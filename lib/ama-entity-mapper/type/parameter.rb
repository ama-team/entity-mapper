# frozen_string_literal: true

require_relative '../mixin/errors'

module AMA
  module Entity
    class Mapper
      class Type
        # This class represents parameter type - an unknown-until-runtime type
        # that belongs to particular other type. For example,
        # Hash<Symbol, Integer> may be described as Type(Hash) with
        # parameters _key: Symbol and _value: Integer
        class Parameter
          include Mixin::Errors

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

          def instance?(_)
            false
          end

          def resolve_parameter(*)
            self
          end

          def resolved?
            false
          end

          def resolved!(context = nil)
            compliance_error("Type #{self} is not resolved", context: context)
          end

          def to_s
            "Parameter #{owner.type}.#{id}"
          end

          def to_def
            "#{owner.type}.#{id}"
          end

          def hash
            @owner.hash ^ @id.hash
          end

          def eql?(other)
            return false unless other.is_a?(self.class)
            @id == other.id && @owner == other.owner
          end

          def ==(other)
            eql?(other)
          end
        end
      end
    end
  end
end
