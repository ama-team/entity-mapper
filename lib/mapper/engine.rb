# frozen_string_literal: true

require_relative 'path'
require_relative 'mixin/errors'
require_relative 'type/registry'
require_relative 'engine/normalizer'
require_relative 'engine/denormalizer'
require_relative 'engine/context'

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
          @normalizer = Normalizer.new(@registry)
          @denormalizer = Denormalizer.new(@registry)
        end

        # @param [Object] source
        # @param [Array<AMA::Entity::Mapper::Type::Concrete>] types
        # @param [Hash] context
        def map(source, *types, **context)
          context = create_context(context)
          types.each do |type|
            type.resolved!(context)
          end
          recursive_map(source, types, context)
        end

        private

        # @return [AMA::Entity::Mapper::Engine::Context] context
        def create_context(options)
          options = options.merge(
            normalizer: @normalizer,
            denormalizer: @denormalizer,
            path: Path.new
          )
          Context.new(**options)
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
          if suppressed.empty?
            message = 'Requested map operation with no target types'
            compliance_error(message, context: context)
          end
          message = "Failed to map #{source.class} " \
            "to any of provided types (#{types})"
          mapping_error(message, parent: suppressed.last, context: context)
        end

        # @param [Object] source
        # @param [AMA::Entity::Mapper::Type] type
        # @param [AMA::Entity::Mapper::Engine::Context] context
        def try_map(source, type, context)
          return source if type.satisfied_by?(source)
          normalized = @normalizer.normalize(source, context, type)
          result = @denormalizer.denormalize(normalized, type, context)
          return result if type.satisfied_by?(result)
          type.instance!(result, context)
          result = map_attributes(result, type, context)
          return result if type.satisfied_by?(result)
          message = "Failed to map #{source.class} to type #{type}"
          mapping_error(message, context: context)
        end

        # @param [Object] entity
        # @param [AMA::Entity::Mapper::Type] type
        # @param [AMA::Entity::Mapper::Engine::Context] context
        def map_attributes(entity, type, context)
          enumerator = type.enumerator(entity)
          acceptor = type.acceptor(entity)
          enumerator.each do |attribute, value, segment = nil|
            unless attribute.satisfied_by?(value)
              segment = Path::Segment.attribute(attribute.name) unless segment
              next_context = context.advance(segment)
              value = recursive_map(value, attribute.types, next_context)
            end
            acceptor.accept(attribute, value, segment)
          end
          entity
        end
      end
    end
  end
end
