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
            def validate!(entity, type, context)
              enumerator = type.enumerator.enumerate(entity, type, context)
              enumerator.each do |attribute, value, segment = nil|
                next_context = segment.nil? ? context : context.advance(segment)
                attribute.validator.validate!(value, attribute, next_context)
              end
            end
          end
        end
      end
    end
  end
end
