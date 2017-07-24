# frozen_string_literal: true

require_relative '../lib/mapper/version'
require_relative '../lib/mapper/engine'

module AMA
  module Entity
    # Entrypoint class which provides basic user access
    class Mapper
      def initialize(engine = nil)
        @engine = engine || Engine.new
      end

      def types
        @engine.registry
      end

      class << self
        def initialize
          @mapper = Mapper.new
        end

        def types
          @mapper.types
        end
      end
    end
  end
end
