# frozen_string_literal: true

require_relative '../entity_validator'

module AMA
  module Entity
    class Mapper
      module API
        module Default
          # Default entity validation
          class EntityValidator < API::EntityValidator
            INSTANCE = new

            # @param [Object] entity
            # @param [Mapper::Type::Concrete] type
            # @param [Mapper::Context] context
            # @return [Array<Array<Attribute, String, Segment>] List of
            #   violations, combined with attribute and segment
            def validate(entity, type, context)
              enumerator = type.enumerator.enumerate(entity, type, context)
              enumerator.flat_map do |attribute, value, segment = nil|
                next_context = segment.nil? ? context : context.advance(segment)
                validator = attribute.validator
                violations = validator.validate(value, attribute, next_context)
                violations.map do |violation|
                  [attribute, violation, segment]
                end
              end
            end
          end
        end
      end
    end
  end
end
