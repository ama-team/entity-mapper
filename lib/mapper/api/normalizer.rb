# frozen_string_literal: true

# rubocop:disable Lint/UnusedMethodArgument

require_relative 'interface'

module AMA
  module Entity
    class Mapper
      module API
        # This interface depicts class normalizer - processor, responsible
        # for converting entity into low-level primitives
        class Normalizer < Interface
          # :nocov:
          # This method takes in provided entity and it's specific type and
          # should return low-level representation of this entity (most
          # commonly, hash of attributes). This normalizer has an option to
          # fall back on default normalization process (using `block.call()`
          # with same signature). Such feature allows to use normalizer as
          # pre- or post-processor, either altering incoming entity or polishing
          # result:
          #
          # ```ruby
          # data = block.call(entity, type, context)
          # data[:parent] = entity.parent.id # replacing parent with it's id
          # data
          # ```
          #
          # It is implied that normalizers *work only on single level*, which
          # means that they should not process underlying attributes. In the
          # example above, that would mean that without additional processing,
          # `data[:parent]` would have parent entity unchanged.
          #
          # @param [Object] entity
          # @param [AMA::Entity::Mapper::Type::Concrete] type
          # @param [AMA::Entity::Mapper::Context] context
          # @param [Proc] block
          # @return [Object]
          def normalize(entity, type, context = nil, &block)
            abstract_method
          end
          # :nocov:
        end
      end
    end
  end
end
