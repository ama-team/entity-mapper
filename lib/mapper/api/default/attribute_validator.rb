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
            # @param [AMA::Entity::Mapper::Context] context
            def validate!(value, attribute, context)
              return if valid_nil?(value, attribute, context)
              validate_type!(value, attribute, context)
              return if value == attribute.default
              validate_values!(value, attribute, context)
            end

            # @param [Object] value Attribute value
            # @param [AMA::Entity::Mapper::Type::Attribute] attribute
            # @param [AMA::Entity::Mapper::Context] context
            def valid_nil?(value, attribute, context)
              return false unless value.nil?
              return true if attribute.nullable
              message = "Attribute #{attribute} could not be nil"
              validation_error(message, context: context)
            end

            # @param [Object] value Attribute value
            # @param [AMA::Entity::Mapper::Type::Attribute] attribute
            # @param [AMA::Entity::Mapper::Context] context
            def validate_values!(value, attribute, context)
              return if attribute.values.empty? || attribute.values.nil?
              return if attribute.values.include?(value)
              message = "Attribute #{attribute} doesn't conform to " \
                'any of allowed values, expected one of: ' \
                "#{attribute.values}, received: #{value}"
              validation_error(message, context: context)
            end

            # @param [Object] value Attribute value
            # @param [AMA::Entity::Mapper::Type::Attribute] attribute
            # @param [AMA::Entity::Mapper::Context] context
            def validate_type!(value, attribute, context)
              return if attribute.types.any? { |type| type.instance?(value) }
              message = "Value #{value} doesn't conform to " \
                "attribute #{attribute} type (#{attribute.types})"
              validation_error(message, context: context)
            end
          end
        end
      end
    end
  end
end
