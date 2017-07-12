# frozen_string_literal: true

# rubocop:disable Lint/UnusedMethodArgument

require_relative 'exception/compliance_error'

module AMA
  module Entity
    class Mapper
      # Base abstract class for all other types
      class Type
        # @return [Hash{Symbol, AMA::Entity::Mapper::Type::Attribute}]
        def attributes
          compliance_error("Type #{self} doesn't support attributes")
        end

        # @return [Hash{Symbol, AMA::Entity::Mapper::Type}]
        def parameters
          compliance_error("Type #{self} doesn't support parameters")
        end

        def supports_parameters?
          false
        end

        def supports_attributes?
          false
        end

        # @param [AMA::Entity::Mapper::Type] parameter
        # @param [AMA::Entity::Mapper::Type] substitution
        def resolve_parameter(parameter, substitution)
          if supports_parameters?
            parameters.each do |id, bound_parameter|
              parameters[id] = substitution if bound_parameter == parameter
            end
          end
          return unless supports_attributes?
          attributes.values.each do |attribute|
            attribute.types = attribute.types.map do |type|
              next substitution if type == parameter
              type.resolve_parameter(parameter, substitution)
              type
            end
          end
        end

        def resolve(parameters)
          parameters.each do |parameter, substitution|
            resolve_parameter(parameter, substitution)
          end
        end

        # @return [TrueClass, FalseClass]
        def resolved?
          if supports_parameters? && !parameters.values.all?(&:resolved?)
            return false
          end
          return true unless supports_attributes?
          attributes.values.flat_map(&:types).all?(&:resolved?)
        end

        # @param [AMA::Entity::Mapper::Type] parameter
        # @return [TrueClass, FalseClass]
        def parameter_of?(parameter)
          parameters.values.include?(parameter)
        end

        # @param [AMA::Entity::Mapper::Type] parameter
        def parameter_of!(parameter)
          return if parameter_of?(parameter)
          message = "Type #{self} doesn't have parameter with type #{parameter}"
          compliance_error(message)
        end

        # @param [Symbol] id
        # @return [TrueClass, FalseClass]
        def parameter?(id)
          parameters.key?(id)
        end

        # @param [Symbol] id
        def parameter!(id)
          return if parameter?(id)
          compliance_error("Type #{self} doesn't have parameter #{id}")
        end

        def absent_parameter!(id)
          return unless parameter?(id)
          compliance_error("Type #{self} has defined parameter #{id}")
        end

        def hash
          abstract_method
        end

        def eql?(other)
          abstract_method
        end

        def ==(other)
          eql?(other)
        end

        def to_s
          abstract_method
        end

        def validate!
          # noop
        end

        protected

        def compliance_error(message)
          raise ::AMA::Entity::Mapper::Exception::ComplianceError, message
        end

        private

        def abstract_method
          message = "Abstract method #{__callee__} hasn't been implemented " \
            "in class #{self.class}"
          raise message
        end
      end
    end
  end
end
