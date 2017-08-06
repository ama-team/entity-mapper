# frozen_string_literal: true

require_relative '../../mixin/reflection'
require_relative '../../mixin/errors'

module AMA
  module Entity
    class Mapper
      module Handler
        module Entity
          # Default normalization handler
          class Normalizer
            include Mixin::Reflection

            INSTANCE = new

            # @param [Object] entity
            # @param [AMA::Entity::Mapper::Type] type
            # @param [AMA::Entity::Mapper::Context] context
            def normalize(entity, type, context)
              type.attributes.values.each_with_object({}) do |attribute, data|
                next if attribute.virtual
                condition = context.include_sensitive_attributes
                next if attribute.sensitive && !condition
                data[attribute.name] = object_variable(entity, attribute.name)
              end
            end

            class << self
              include Mixin::Reflection

              # @param [Normalizer] implementation
              # @return [Normalizer]
              def wrap(implementation)
                handler = handler_factory(implementation, INSTANCE)
                description = "Safety wrapper for #{implementation}"
                wrapper = method_object(:normalize, to_s: description, &handler)
                wrapper.singleton_class.instance_eval do
                  include Mixin::Errors
                end
                wrapper
              end

              private

              # @param [Normalizer] impl
              # @param [Normalizer] fallback
              # @return [Proc]
              def handler_factory(impl, fallback)
                lambda do |entity, type, ctx|
                  begin
                    impl.normalize(entity, type, ctx) do |e, t, c|
                      fallback.normalize(e, t, c)
                    end
                  rescue StandardError => e
                    raise_if_internal(e)
                    message = "Unexpected error from normalizer #{impl}"
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
