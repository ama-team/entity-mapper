# frozen_string_literal: true

require_relative '../attribute_validator'

module AMA
  module Entity
    class Mapper
      module API
        module Wrapper
          # Attribute validator safety wrapper
          class AttributeValidator < API::AttributeValidator
            # @param [AMA::Entity::Mapper::API::AttributeValidator] validator
            def initialize(validator)
              @validator = validator
            end

            # @param [Object] value Attribute value
            # @param [AMA::Entity::Mapper::Type::Attribute] attr
            # @param [AMA::Entity::Mapper::Context] ctx
            # @return [Array<String>] List of violations
            def validate(value, attr, ctx)
              violations = @validator.validate(value, attr, ctx) do |v, a, c|
                API::Default::AttributeValidator::INSTANCE.validate(v, a, c)
              end
              violations = [violations] if violations.is_a?(String)
              violations.nil? ? [] : violations
            rescue StandardError => e
              raise_if_internal(e)
              message = "Error during #{attr} validation (value: #{value})"
              if e.is_a?(ArgumentError)
                message += '. Does provided validator have ' \
                  '(value, attribute, context) signature?'
              end
              compliance_error(message, context: ctx, parent: e)
            end
          end
        end
      end
    end
  end
end
