# frozen_string_literal: true

require_relative 'path'
require_relative 'context'
require_relative 'error'
require_relative 'mixin/errors'
require_relative 'mixin/suppression_support'
require_relative 'type'
require_relative 'type/registry'
require_relative 'type/resolver'
require_relative 'engine/recursive_mapper'
require_relative 'engine/recursive_normalizer'

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
          @normalizer = RecursiveNormalizer.new(@registry)
          @mapper = RecursiveMapper.new(@registry)
        end

        # @param [Object] source
        # @param [Array<AMA::Entity::Mapper::Type>] types
        # @param [Hash] context_options
        def map(source, *types, **context_options)
          context = create_context(context_options)
          types = normalize_types(types, context)
          @mapper.map(source, types, context)
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
          @normalizer.normalize(object, create_context(context_options))
        end

        # @param [Class, Module] klass
        def register(klass)
          @registry[klass] || @registry.register(Type.new(klass))
        end

        # @param [Class, Module] klass
        def [](klass)
          @registry[klass]
        end

        private

        # @param [Hash] options
        # @return [AMA::Entity::Mapper::Engine::Context]
        def create_context(options)
          options = options.merge(path: Path.new)
          Mapper::Context.new(**options)
        end

        # @param [Array<AMA::Entity::Mapper::Type>] types
        def normalize_types(types, context)
          compliance_error('Called #map() with no types') if types.empty?
          types = types.map { |type| @resolver.resolve(type) }
          types.each { |type| type.resolved!(context) }
        end
      end
    end
  end
end
