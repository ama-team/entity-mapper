# frozen_string_literal: true

require_relative '../../mixin/reflection'
require_relative '../../mixin/errors'

module AMA
  module Entity
    class Mapper
      module Handler
        module Entity
          # Default denormalization processor
          class Denormalizer
            include Mixin::Reflection
            include Mixin::Errors

            INSTANCE = new

            # @param [Hash] source
            # @param [AMA::Entity::Mapper::Type] type
            # @param [AMA::Entity::Mapper::Context] context
            def denormalize(source, type, context = nil)
              validate_source!(source, type, context)
              entity = type.factory.create(type, source, context)
              type.attributes.values.each do |attribute|
                next if attribute.virtual
                [attribute.name.to_s, attribute.name].each do |name|
                  next unless source.key?(name)
                  set_object_attribute(entity, name, source[name])
                end
              end
              entity
            end

            private

            # @param [Hash] source
            # @param [AMA::Entity::Mapper::Type] type
            # @param [AMA::Entity::Mapper::Context] context
            def validate_source!(source, type, context)
              return if source.is_a?(Hash)
              message = "Expected Hash, #{source.class} provided " \
                "(while denormalizing #{type})"
              mapping_error(message, context: context)
            end

            class << self
              include Mixin::Reflection

              # @param [Denormalizer] implementation
              # @return [Denormalizer]
              def wrap(implementation)
                handler = handler_factory(implementation, INSTANCE)
                depiction = "Safety wrapper for #{implementation}"
                wrapper = method_object(:denormalize, to_s: depiction, &handler)
                wrapper.singleton_class.instance_eval do
                  include Mixin::Errors
                end
                wrapper
              end

              private

              # @param [Denormalizer] implementation
              # @param [Denormalizer] fallback
              # @return [Denormalizer]
              def handler_factory(implementation, fallback)
                lambda do |source, type, ctx|
                  begin
                    implementation.denormalize(source, type, ctx) do |s, t, c|
                      fallback.denormalize(s, t, c)
                    end
                  rescue StandardError => e
                    raise_if_internal(e)
                    message = 'Unexpected error from denormalizer ' \
                      "#{implementation}"
                    signature = '(source, type, context)'
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
