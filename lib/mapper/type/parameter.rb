# frozen_string_literal: true

module AMA
  module Entity
    class Mapper
      module Type
        # Used to fill in types that would be known later at runtime
        class Parameter
          attr_reader :owner
          attr_reader :id

          # @param [Class] owner
          # @param [Symbol] id
          def initialize(owner, id)
            @owner = owner
            @id = id
          end

          def to_s
            "Parameter :#{id} (declared in #{owner})"
          end

          def hash
            @owner.hash ^ @id.hash
          end

          def eql?(other)
            return false unless other.is_a?(self.class)
            id == other.id && owner == other.owner
          end
        end
      end
    end
  end
end
