# frozen_string_literal: true

require_relative '../entity_validator'
require_relative '../../type/attribute'

module AMA
  module Entity
    class Mapper
      module API
        module Wrapper
          # Default entity validation
          class EntityValidator < API::EntityValidator
            # @param [AMA::Entity::Mapper::API::EntityValidator] validator
            def initialize(validator)
              @validator = validator
            end

            # @param [Object] entity
            # @param [Mapper::Type::Concrete] type
            # @param [Mapper::Context] context
            # @return [Array<Array<Attribute, String, Segment>] List of
            #   violations, combined with attribute and segment
            def validate(entity, type, context)
              result = @validator.validate(entity, type, context) do |e, t, c|
                API::Default::EntityValidator::INSTANCE.validate(e, t, c)
              end
              verify_result!(result, type, context)
              result
            rescue StandardError => e
              raise_if_internal(e)
              message = "Error during #{type} validation (entity: #{entity})"
              if e.is_a?(ArgumentError)
                message += '. Does provided validator have ' \
                  '(entity, type, context) signature?'
              end
              compliance_error(message, context: context, parent: e)
            end

            private

            def verify_result!(result, type, context)
              unless result.is_a?(Array)
                message = "Validator #{@validator} for type #{type} " \
                  'had to return list of violations, ' \
                  "#{result} was received instead"
                compliance_error(message, context: context)
              end
              result.each do |violation|
                verify_violation!(violation, type, context)
              end
            end

            def verify_violation!(violation, type, context)
              message = "Validator #{@validator} for type #{type} " \
                  "has returned #{violation} as violation " \
                  '([attribute, violation, path segment] expected)'
              unless violation.is_a?(Array) || violation.size == 3
                compliance_error(message, context: context)
              end
              conditions = [
                violation[0].is_a?(Type::Attribute),
                violation[1].is_a?(String),
                violation[2].is_a?(Path::Segment) || violation[2].nil?
              ]
              return if conditions.all?(&:itself)
              compliance_error(message, context: context)
            end
          end
        end
      end
    end
  end
end
