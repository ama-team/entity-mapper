# frozen_string_literal: true

require_relative '../../mixin/reflection'
require_relative '../../mixin/errors'

module AMA
  module Entity
    class Mapper
      module Handler
        module Entity
          # Default entity validator
          class Validator
            INSTANCE = new

            # @param [Object] entity
            # @param [Mapper::Type::Concrete] type
            # @param [Mapper::Context] context
            # @return [Array<Array<Attribute, String, Segment>] List of
            #   violations, combined with attribute and segment
            def validate(entity, type, context)
              enumerator = type.enumerator.enumerate(entity, type, context)
              enumerator.flat_map do |attribute, value, segment = nil|
                next [] if attribute.virtual
                next_context = segment.nil? ? context : context.advance(segment)
                validator = attribute.validator
                violations = validator.validate(value, attribute, next_context)
                violations.map do |violation|
                  [attribute, violation, segment]
                end
              end
            end

            class << self
              include Mixin::Reflection

              # @param [Validator] validator
              # @return [Validator]
              def wrap(validator)
                handler = handler_factory(validator, INSTANCE)
                description = "Safety wrapper for #{validator}"
                wrapper = method_object(:validate, to_s: description, &handler)
                wrapper.singleton_class.instance_eval do
                  include Mixin::Errors
                end
                wrapper
              end

              private

              # @param [Validator] validator
              # @param [Validator] fallback
              # @return [Proc]
              def handler_factory(validator, fallback)
                lambda do |entity, type, ctx|
                  begin
                    validator.validate(entity, type, ctx) do |e, t, c|
                      fallback.validate(e, t, c)
                    end
                  rescue StandardError => e
                    raise_if_internal(e)
                    message = "Unexpected error from validator #{validator}"
                    signature = '(entity, type, context)'
                    options = { parent: e, context: ctx, signature: signature }
                    compliance_error(message, **options)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
