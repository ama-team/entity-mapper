# frozen_string_literal: true

require_relative '../../mixin/errors'
require_relative '../../mixin/reflection'
require_relative '../../path/segment'

module AMA
  module Entity
    class Mapper
      module Handler
        module Entity
          # Default entity factory
          class Factory
            include Mixin::Errors

            INSTANCE = new

            # @param [AMA::Entity::Mapper::Type] type
            # @param [Object] _data
            # @param [AMA::Entity::Mapper::Context] context
            def create(type, _data, context)
              create_internal(type)
            rescue StandardError => e
              message = "Failed to instantiate #{type} directly from class"
              if e.is_a?(ArgumentError)
                message += '. Does it have parameterless #initialize() method?'
              end
              mapping_error(message, parent: e, context: context)
            end

            private

            # @param [AMA::Entity::Mapper::Type] type
            def create_internal(type)
              entity = type.type.new
              type.attributes.values.each do |attribute|
                next if attribute.default.nil? || attribute.virtual
                segment = Path::Segment.attribute(attribute.name)
                value = attribute.default
                type.injector.inject(entity, type, attribute, value, segment)
              end
              entity
            end

            class << self
              include Mixin::Reflection

              # @param [Factory] implementation
              # @return [Factory]
              def wrap(implementation)
                handler = handler_factory(implementation, INSTANCE)
                description = "Safety wrapper for #{implementation}"
                wrapper = method_object(:create, to_s: description, &handler)
                wrapper.singleton_class.instance_eval do
                  include Mixin::Errors
                end
                wrapper
              end

              private

              # @param [Factory] implementation
              # @param [Factory] fallback
              # @return [Factory]
              def handler_factory(implementation, fallback)
                lambda do |type, data, ctx|
                  begin
                    implementation.create(type, data, ctx) do |t, d, c|
                      fallback.create(t, d, c)
                    end
                  rescue StandardError => e
                    raise_if_internal(e)
                    message = "Unexpected error from factory #{implementation}"
                    signature = '(type, data, context)'
                    options = { parent: e, context: ctx, signature: signature }
                    compliance_error(message, options)
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
