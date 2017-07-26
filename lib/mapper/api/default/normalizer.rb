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
            # @param [AMA::Entity::Mapper::Type] type
            # @param [AMA::Entity::Mapper::Context] _context
            def normalize(entity, type, _context = nil)
              type.attributes.values.each_with_object({}) do |attribute, data|
                next if attribute.virtual || attribute.sensitive
                data[attribute.name] = object_variable(entity, attribute.name)
              end
            end
          end
        end
      end
    end
  end
end
