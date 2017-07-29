# frozen_string_literal: true

require_relative '../denormalizer'
require_relative '../../mixin/reflection'
require_relative '../../mixin/errors'

module AMA
  module Entity
    class Mapper
      module API
        module Default
          # Default denormalization processor
          class Denormalizer < API::Denormalizer
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

            def validate_source!(source, type, context)
              return if source.is_a?(Hash)
              message = "Expected Hash, #{source.class} provided " \
                "(while denormalizing #{type})"
              mapping_error(message, context: context)
            end
          end
        end
      end
    end
  end
end
