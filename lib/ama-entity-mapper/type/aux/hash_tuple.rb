# frozen_string_literal: true

module AMA
  module Entity
    class Mapper
      class Type
        module Aux
          # Simple class to store paired data items
          class HashTuple
            attr_accessor :key
            attr_accessor :value

            def initialize(key: nil, value: nil)
              @key = key
              @value = value
            end

            def hash
              @key.hash ^ @value.hash
            end

            def eql?(other)
              return false unless other.is_a?(HashTuple)
              @key == other.key && @value == other.value
            end

            def ==(other)
              eql?(other)
            end
          end
        end
      end
    end
  end
end
