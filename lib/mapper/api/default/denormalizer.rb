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

            # @param [Object] entity
            # @param [Hash] source
            # @param [AMA::Entity::Mapper::Type] type
            # @param [AMA::Entity::Mapper::Context] context
            def denormalize(entity, source, type, context = nil)
              return set_object_attributes(entity, source) if source.is_a?(Hash)
              message = "Expected hash, #{source.class} provided " \
                "(while denormalizing #{type})"
              mapping_error(message, context: context)
            end
          end
        end
      end
    end
  end
end
