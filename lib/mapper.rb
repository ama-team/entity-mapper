# frozen_string_literal: true

require_relative 'mapper/version'
require_relative 'mapper/engine'
require_relative 'mapper/type'
require_relative 'mapper/type/registry'

module AMA
  module Entity
    # Entrypoint class which provides basic user access
    class Mapper
      class << self
        attr_writer :engine

        def engine
          @engine ||= Engine.new(Type::Registry.new.with_default_types)
        end

        def types
          engine.registry
        end

        def resolve(definition)
          engine.resolve(definition)
        end

        def map(input, *types, **options)
          engine.map(input, *types, **options)
        end

        def normalize(input, **options)
          engine.normalize(input, **options)
        end

        def [](klass)
          engine.registry[klass]
        end
      end
    end
  end
end
