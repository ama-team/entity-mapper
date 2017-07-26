# frozen_string_literal: true

require_relative 'path'
require_relative 'context'
require_relative 'mixin/errors'
require_relative 'type/registry'
require_relative 'type/concrete'
require_relative 'engine/normalizer'
require_relative 'engine/denormalizer'

module AMA
  module Entity
    class Mapper
      # Main, user-unfriendly, library-entrypoint class. Provides interface for
      # mapping one type into another.
      class Engine
        include Mixin::Errors

        attr_reader :registry

        def initialize(registry = nil)
          @registry = registry || Type::Registry.new
          @normalizer = Normalizer.new
          @denormalizer = Denormalizer.new
        end

        # @param [Object] source
        # @param [Array<AMA::Entity::Mapper::Type::Concrete>] types
        # @param [Hash] context_options
        def map(source, *types, **context_options)
          context = create_context(context_options)
          types = normalize_types(types, context)
          begin
            recursive_map(source, types, context)
          rescue StandardError => e
            message = "Failed to map #{source.class} " \
              "to any of provided types (#{types.map(&:to_s).join(', ')}). " \
              "Last error: #{e.message}"
            mapping_error(message, context: context)
          end
        end

        private

        # @return [AMA::Entity::Mapper::Engine::Context] context
        def create_context(options)
          options = options.merge(
            normalizer: @normalizer,
            denormalizer: @denormalizer,
            path: Path.new
          )
          Mapper::Context.new(**options)
        end

        # @param [Object] source
        # @param [Array<AMA::Entity::Mapper::Type>] types
        # @param [AMA::Entity::Mapper::Engine::Context] context
        def recursive_map(source, types, context)
          suppressed = []
          types.each do |type|
            begin
              return try_map(source, type, context)
            rescue StandardError => e
              suppressed.push(e)
            end
          end
          # types are guaranteed to be non-empty in #map
          raise suppressed.last
        end

        # @param [Object] source
        # @param [AMA::Entity::Mapper::Type] type
        # @param [AMA::Entity::Mapper::Engine::Context] context
        def try_map(source, type, context)
          return source if type.satisfied_by?(source)
          result = reassemble(source, type, context)
          return result if type.satisfied_by?(result)
          result = map_attributes(result, type, context)
          return result if type.satisfied_by?(result)
          message = "Failed to map #{source.class} to type #{type}"
          mapping_error(message, context: context)
        end

        def reassemble(source, type, context)
          return source if type.instance?(source)
          source_type = registry.find(source.class)
          source_type ||= Type::Concrete.new(source.class)
          normalized = @normalizer.normalize(source, source_type, context)
          result = @denormalizer.denormalize(normalized, type, context)
          type.instance!(result, context)
          result
        end

        # @param [Object] entity
        # @param [AMA::Entity::Mapper::Type] type
        # @param [AMA::Entity::Mapper::Engine::Context] context
        def map_attributes(entity, type, context)
          instance = type.factory.create(type, entity, context)
          enumerator = type.enumerator.enumerate(entity, type, context)
          enumerator.each do |attribute, value, segment = nil|
            segment = Path::Segment.attribute(attribute.name) unless segment
            next_context = context.advance(segment)
            unless attribute.satisfied_by?(value)
              value = recursive_map(value, attribute.types, next_context)
            end
            type.injector.inject(instance, type, attribute, value, next_context)
          end
          instance
        end

        def normalize_types(types, context)
          if types.empty?
            compliance_error('Requested map operation with no target types')
          end
          types = types.map do |type|
            normalize_type(type)
          end
          types.each do |type|
            type.resolved!(context)
          end
        end

        def normalize_type(type)
          return type if type.is_a?(Type)
          parameters = {}
          type, parameters = type if type.is_a?(Array)
          if [Module, Class].any? { |candidate| type.is_a?(candidate) }
            type = @registry[type] || Type::Concrete.new(type)
          end
          unless type.is_a?(Type)
            message = "Provided type in unknown format: #{type}, " \
              'Type/Class/Module expected'
            compliance_error(message)
          end
          type.resolve(parameters)
        end
      end
    end
  end
end
