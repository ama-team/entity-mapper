# frozen_string_literal: true

require_relative '../../mixin/reflection'
require_relative '../../mixin/errors'

module AMA
  module Entity
    class Mapper
      module Handler
        module Entity
          # Default attribute injector
          class Injector
            include Mixin::Reflection

            INSTANCE = new

            # @param [Object] entity
            # @param [AMA::Entity::Mapper::Type] _type
            # @param [AMA::Entity::Mapper::Type::Attribute] attribute
            # @param [Object] value
            # @param [AMA::Entity::Mapper::Context] _context
            def inject(entity, _type, attribute, value, _context = nil)
              return entity if attribute.virtual
              set_object_attribute(entity, attribute.name, value)
              entity
            end

            class << self
              include Mixin::Reflection

              # @param [Injector] implementation
              # @return [Injector]
              def wrap(implementation)
                handler = handler_factory(implementation, INSTANCE)
                description = "Safety wrapper for #{implementation}"
                wrapper = method_object(:inject, to_s: description, &handler)
                wrapper.singleton_class.instance_eval do
                  include Mixin::Errors
                end
                wrapper
              end

              private

              # @param [Injector] impl
              # @param [Injector] fallback
              # @return [Injector]
              def handler_factory(impl, fallback)
                lambda do |entity, type, attr, val, ctx|
                  begin
                    impl.inject(entity, type, attr, val, ctx) do |e, t, a, v, c|
                      fallback.inject(e, t, a, v, c)
                    end
                  rescue StandardError => e
                    raise_if_internal(e)
                    message = "Unexpected error from injector #{impl}"
                    signature = '(entity, type, attr, val, ctx)'
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
