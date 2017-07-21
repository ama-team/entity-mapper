# frozen_string_literal: true

module AMA
  module Entity
    class Mapper
      class Type
        module Aux
          # Simple class to store paired data items
          class Pair
            attr_accessor :left
            attr_accessor :right

            def initialize(left: nil, right: nil)
              @left = left
              @right = right
            end

            def hash
              @left.hash ^ @right.hash
            end

            def eql?(other)
              return false unless other.is_a?(Pair)
              @left == other.left && @right == other.right
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
