# frozen_string_literal: true

require_relative '../attribute_validator'

module AMA
  module Entity
    class Mapper
      module API
        module Wrapper
          # Attirubte validator safety wrapper
          class AttributeValidator < API::AttributeValidator
            # @param [AMA::Entity::Mapper::API::AttributeValidator] validator
            def initialize(validator)
              @validator = validator
            end

            # @param [Object] value Attribute value
            # @param [AMA::Entity::Mapper::Type::Attribute] attribute
            # @param [AMA::Entity::Mapper::Context] context
            def validate!(value, attribute, context)
              @validator.validate!(value, attribute, context) do |v, a, c|
                API::Default::AttributeValidator::INSTANCE.validate!(v, a, c)
              end
            rescue StandardError => e
              # validation errors are also considered internal and would
              # be reraised
              raise_if_internal(e)
              message = "Error during #{attribute} validation (value: #{value})"
              if e.is_a?(ArgumentError)
                message += '. Does provided validator have ' \
                  '(value, attribute, context) signature?'
              end
              compliance_error(message, context: context, parent: e)
            end
          end
        end
      end
    end
  end
end
