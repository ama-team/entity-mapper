# frozen_string_literal: true

require_relative '../entity_validator'

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
            def validate!(entity, type, context)
              @validator.validate!(entity, type, context) do |e, t, c|
                API::Default::EntityValidator::INSTANCE.validate!(e, t, c)
              end
            rescue StandardError => e
              # validation errors are also considered internal and would
              # be reraised
              raise_if_internal(e)
              message = "Error during #{type} validation (entity: #{entity})"
              if e.is_a?(ArgumentError)
                message += '. Does provided validator have ' \
                  '(entity, type, context) signature?'
              end
              compliance_error(message, context: context, parent: e)
            end
          end
        end
      end
    end
  end
end
