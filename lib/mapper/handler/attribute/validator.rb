# frozen_string_literal: true

require_relative '../../mixin/reflection'
require_relative '../../mixin/errors'

module AMA
  module Entity
    class Mapper
      module Handler
        module Attribute
          # Default validator for single attribute
          class Validator
            INSTANCE = new

            # @param [Object] value Attribute value
            # @param [AMA::Entity::Mapper::Type::Attribute] attribute
            # @param [AMA::Entity::Mapper::Context] _context
            # @return [Array<String>] Single violation, list of violations
            def validate(value, attribute, _context)
              violation = validate_internal(value, attribute)
              violation.nil? ? [] : [violation]
            end

            private

            def validate_internal(value, attribute)
              if illegal_nil?(value, attribute)
                return "Attribute #{attribute} could not be nil"
              end
              if invalid_type?(value, attribute)
                return "Provided value doesn't conform to " \
                  "any of attribute #{attribute} types " \
                  "(#{attribute.types.map(&:to_def).join(', ')})"
              end
              return unless illegal_value?(value, attribute)
              "Provided value doesn't match default value (#{value})" \
                " or any of allowed values (#{attribute.values})"
            end

            # @param [Object] value Attribute value
            # @param [AMA::Entity::Mapper::Type::Attribute] attribute
            # @return [TrueClass, FalseClass]
            def illegal_nil?(value, attribute)
              return false unless value.nil? && !attribute.nullable
              attribute.types.none? { |type| type.instance?(value) }
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
                lambda do |val, attr, ctx|
                  begin
                    validator.validate(val, attr, ctx) do |v, a, c|
                      fallback.validate(v, a, c)
                    end
                  rescue StandardError => e
                    raise_if_internal(e)
                    message = "Unexpected error from validator #{validator}"
                    signature = '(value, attribute, context)'
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
