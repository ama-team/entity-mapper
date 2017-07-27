# frozen_string_literal: true

require_relative 'mapper/version'
require_relative 'mapper/engine'
require_relative 'mapper/type/concrete'

module AMA
  module Entity
    # Entrypoint class which provides basic user access
    class Mapper
      attr_reader :engine

      def initialize(engine = nil)
        @engine = engine || Engine.new
      end

      def types
        @engine.registry
      end

      def register(klass)
        return types[klass] if types.key?(klass)
        types.register(Type::Concrete.new(klass))
      end

      def resolve(type)
        @engine.resolve(type)
      end

      class << self
        def initialize
          @mapper = Mapper.new
        end

        def swap(mapper)
          @mapper = mapper
        end

        def handler
          @mapper
        end

        Mapper.instance_methods(false).each do |method|
          next if method_defined?(method)
          define_method method do |*args|
            @mapper.send(method, *args)
          end
        end
      end
    end
  end
end
