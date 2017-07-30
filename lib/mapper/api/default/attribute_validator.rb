# frozen_string_literal: true

require_relative '../attribute_validator'

module AMA
  module Entity
    class Mapper
      module API
        module Default
          # Default validator for single attribute
          class AttributeValidator < API::AttributeValidator
            INSTANCE = new

            # @param [Object] value Attribute value
            # @param [AMA::Entity::Mapper::Type::Attribute] attribute
            # @return [Array<String>] Single violation, list of violations
            def validate(value, attribute, *)
              violations = validate_internal(value, attribute)
              violations.nil? ? [] : [violations]
            end

            private

            def validate_internal(value, attribute)
              if illegal_nil?(value, attribute)
                return "Attribute #{attribute} could not be nil"
              end
              if invalid_type?(value, attribute)
                return "Provided value #{value} doesn't conform to " \
                  "any of attribute #{attribute} types (#{attribute.types})"
              end
              return unless illegal_value?(value, attribute)
              "Provided value #{value} doesn't match default value (#{value})" \
                " or any of allowed values (#{attribute.values})"
            end

            # @param [Object] value Attribute value
            # @param [AMA::Entity::Mapper::Type::Attribute] attribute
            # @return [TrueClass, FalseClass]
            def illegal_nil?(value, attribute)
              value.nil? && !attribute.nullable
            end

            # @param [Object] value Attribute value
            # @param [AMA::Entity::Mapper::Type::Attribute] attribute
            # @return [TrueClass, FalseClass]
            def invalid_type?(value, attribute)
              attribute.types.all? do |type|
                !type.respond_to?(:instance?) || !type.instance?(value)
              end
            end

            # @param [Object] value Attribute value
            # @param [AMA::Entity::Mapper::Type::Attribute] attribute
            # @return [TrueClass, FalseClass]
            def illegal_value?(value, attribute)
              return false if value == attribute.default
              return false if attribute.values.empty? || attribute.values.nil?
              !attribute.values.include?(value)
            end
          end
        end
      end
    end
  end
end
