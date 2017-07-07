# frozen_string_literal: true

require_relative 'parameter'
require_relative 'any'
require_relative 'concrete'
require_relative '../exception/compliance_error'

module AMA
  module Entity
    class Mapper
      module Type
        # This class is used to serve as proxy for real types
        class Proxy
          attr_accessor :type

          def resolved?
            return true if type.is_a?(Any)
            return false if type.is_a?(Parameter)
            type.resolved?
          end

          def resolvable?
            type.is_a?(Concrete)
          end

          def resolve_parameter(parameter, substitution)
            if resolvable?
              return type.resolve_parameter(parameter, substitution)
            end
            message = "Tried to resolve #{self.class} type " \
              "with parameter #{parameter} => #{substitution}"
            compliance_error(message)
          end

          def hash
            type.hash
          end

          def eql?(o)
            o.is_a?(self.class) && o.type == @type
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
