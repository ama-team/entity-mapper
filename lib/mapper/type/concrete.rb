# frozen_string_literal: true

require_relative '../exception/compliance_error'
require_relative 'any'

module AMA
  module Entity
    class Mapper
      module Type
        # Used to describe concrete type (that means, class is already known,
        # though it's parameters may be resolved later).
        class Concrete
          # @!attribute type
          #   @return [Class]
          attr_accessor :type
          # @!attribute parameters
          #   @return [Hash{Symbol, AMA::Entity::Mapper::Type::Proxy}]
          attr_accessor :parameters
          # @!attribute attributes
          #   @return [Hash{Symbol, AMA::Entity::Mapper::Type::Attribute}]
          attr_accessor :attributes

          def initialize(type)
            @type = type
            @parameters = {}
            @attributes = {}
          end

          def resolved?
            parameters.values.all?(&:resolved?) &&
              attributes.values.map(&:type).all?(&:resolved?)
          end

          def parameter?(parameter)
            parameters.key?(parameter)
          end

          def resolve_parameter(parameter, substitution)
            unless parameter?(parameter)
              message = "Tried to resolve nonexistent parameter #{parameter} " \
                "on type #{self}"
              compliance_error message
            end
            parameters[parameter] = substitution
          end

          def hash
            @type.hash ^ @parameters.hash ^ @attributes.hash
          end

          def eql?(other)
            return true if other.is_a?(Any)
            return false unless other.is_a?(self.class)
            @type == other.type &&
              @parameters == other.parameters &&
              @attributes == other.attributes
          end

          def to_s
            "Concrete type #{@type}"
          end

          private

          def compliance_error(message)
            raise ::AMA::Entity::Mapper::Exception::ComplianceError, message
          end
        end
      end
    end
  end
end
