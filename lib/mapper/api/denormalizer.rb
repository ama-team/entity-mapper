# frozen_string_literal: true

# rubocop:disable Lint/UnusedMethodArgument

require_relative 'interface'

module AMA
  module Entity
    class Mapper
      module API
        # This interface depicts class denormalizer - processor, responsible
        # for populating entity from low-level primitives and context
        class Denormalizer < Interface
          # This methods accepts blank entity, data and type and populates
          # entity.
          #
          # Method is provided with context and fallback block (with same
          # signature) that allows to use default denormalization process. This
          # allows denormalizer to use context to populate entity or use
          # fallback block before or after processing:
          #
          # ```ruby
          # data = { id: data } if data.is_a?(String) || data.is_a?(Symbol)
          # block.call(entity, data, type, context)
          # entity.id = entity.id || context.path.current.name
          # entity
          # ```
          #
          # This method should not attempt to denormalize attributes, since that
          # would be taken care of by mapper itself.
          #
          # @param [Object] entity
          # @param [Object] data
          # @param [AMA::Entity::Mapper::Type::Concrete] type
          # @param [AMA::Entity::Mapper::Context] context
          # @param [Proc] block
          # @return [Object]
          def denormalize(entity, data, type, context = nil, &block)
            abstract_method
          end
        end
      end
    end
  end
end
