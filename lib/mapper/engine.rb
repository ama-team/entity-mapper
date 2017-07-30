# frozen_string_literal: true

require_relative 'path'
require_relative 'context'
require_relative 'mixin/errors'
require_relative 'type/registry'
require_relative 'type/resolver'
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

        # @!attribute [r] registry
        #   @return [Type::Registry]
        attr_reader :registry
        # @!attribute [r] resolver
        #   @return [Type::Resolver]
        attr_reader :resolver

        # @param [Type::Registry] registry
        def initialize(registry = nil)
          @registry = registry || Type::Registry.new
          @resolver = Type::Resolver.new(@registry)
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

        # Resolves provided definition, creating type hierarchy.
        # @param [Array<Class, Module, Type, Array>] definition
        def resolve(definition)
          @resolver.resolve(definition)
        end

        # Normalizes object to primitive data structures.
        # @param [Object] object
        # @param [Hash] context_options
        def normalize(object, **context_options)
          recursive_normalize(object, create_context(context_options))
        end

        private

        # @param [Object] object
        # @param [AMA::Entity::Mapper::Context] context
        # @return [Object]
        def recursive_normalize(object, context)
          data = @normalizer.normalize(object, find_type(source.class), context)
          type = find_type(data)
          target = type.factory.create(type, data, context)
          type.enumerator.enumerate(data, type, context) do |attr, val, segment|
            next_context = segment.nil? ? context : context.advance(segment)
            val = recursive_normalize(val, next_context)
            type.injector.inject(target, type, attr, val, next_context)
          end
          target
        end

        # @return [AMA::Entity::Mapper::Engine::Context] context
        def create_context(options)
          options = options.merge(
            normalizer: @normalizer,
            denormalizer: @denormalizer,
            path: Path.new
          )
          Mapper::Context.new(**options)
        end

        def find_type(klass)
          @registry.find(klass) || Type::Concrete.new(klass)
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
          unless type.valid?(source, context)
            source = reassemble(source, type, context)
          end
          result = map_attributes(source, type, context)
          type.valid!(result, context)
          result
        end

        # Normalizes and then denormalizes entity
        #
        # @param [Object] source
        # @param [AMA::Entity::Mapper::Type] type
        # @param [AMA::Entity::Mapper::Engine::Context] context
        def reassemble(source, type, context)
          return source if type.instance?(source)
          source_type = find_type(source.class)
          normalized = @normalizer.normalize(source, source_type, context)
          result = @denormalizer.denormalize(normalized, type, context)
          type.instance!(result, context)
          result
        end

        # @param [Object] entity
        # @param [AMA::Entity::Mapper::Type] type
        # @param [AMA::Entity::Mapper::Engine::Context] context
        def map_attributes(entity, type, context)
          enumerator = type.enumerator.enumerate(entity, type, context)
          return entity if enumerator.none? { true }
          changes = enumerator.map do |attribute, value, segment = nil|
            if value.nil? && attribute.nullable
              next [false, attribute, value, segment]
            end
            next_context = segment ? context.advance(segment) : context
            mutated = recursive_map(value, attribute.types, next_context)
            [!value.equal?(mutated), attribute, mutated, segment]
          end
          changes = changes.reject(&:nil?)
          return entity if changes.select(&:first).empty?
          instance = type.factory.create(type, entity, context)
          changes.map do |_, attribute, value, segment = nil|
            next_context = segment ? context.advance(segment) : context
            type.injector.inject(instance, type, attribute, value, next_context)
          end
          instance
        end

        def normalize_types(types, context)
          if types.empty?
            compliance_error('Requested map operation with no target types')
          end
          types = types.map do |type|
            @resolver.resolve(type)
          end
          types.each do |type|
            type.resolved!(context)
          end
        end
      end
    end
  end
end
