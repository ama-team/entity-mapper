# frozen_string_literal: true

module AMA
  module Entity
    class Mapper
      class Type
        # Used as a wildcard to pass anything through
        class Any < Type
          INSTANCE = new

          def hash
            self.class.hash
          end

          def eql?(other)
            other.is_a?(Type)
          end

          def to_s
            'Any type placeholder'
          end
        end
      end
    end
  end
end
