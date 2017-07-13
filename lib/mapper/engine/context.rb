# frozen_string_literal: true

require_relative '../path'

module AMA
  module Entity
    class Mapper
      class Engine
        # Normalization/denormalization context. Holds current path relatively
        # to processed item and some options.
        class Context
          # @!attribute path
          #   @return [Path]
          attr_reader :path
          attr_accessor :use_normalize_method
          attr_accessor :use_denormalize_method

          def initialize(path = nil)
            @path = path || Path.new
            @use_normalize_method = true
            @use_denormalize_method = true
          end

          def advance(type, key)
            self.class.new(path.send(type, key))
          end
        end
      end
    end
  end
end
