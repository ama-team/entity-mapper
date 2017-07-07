# frozen_string_literal: true

module AMA
  module Entity
    class Mapper
      module Type
        # Used as a wildcard to pass anything through
        class Any
          def hash
            self.class.hash
          end

          def eql?(*)
            true
          end
        end
      end
    end
  end
end
