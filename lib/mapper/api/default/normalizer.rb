# frozen_string_literal: true

require_relative '../normalizer'
require_relative '../../mixin/reflection'

module AMA
  module Entity
    class Mapper
      module API
        module Default
          # Default denormalization processor
          class Normalizer < API::Normalizer
            include Mixin::Reflection

            INSTANCE = new

            # @param [Object] entity
            # @param [AMA::Entity::Mapper::Type] _type
            # @param [AMA::Entity::Mapper::Context] _context
            def normalize(entity, _type, _context = nil)
              object_variables(entity)
            end
          end
        end
      end
    end
  end
end
