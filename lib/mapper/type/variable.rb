# frozen_string_literal: true

require_relative 'parameter'
require_relative 'any'
require_relative '../type'
require_relative '../exception/compliance_error'

module AMA
  module Entity
    class Mapper
      class Type
        # This class represents variable type - a type that is known only in
        # runtime when user specifies it
        class Variable < Type
          # @!attribute type
          #   @return [AMA::Entity::Mapper::Type]
          attr_reader :owner
          # @!attribute id
          #   @return [Symbol]
          attr_reader :id

          # @param [AMA::Entity::Mapper::Type] owner
          # @param [Symbol] id
          def initialize(owner, id)
            @owner = owner
            @id = id
          end

          def resolved?
            false
          end

          def to_s
            "Variable Type :#{id} (declared in #{owner})"
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
