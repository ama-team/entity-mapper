# frozen_string_literal: true

require_relative '../injector'
require_relative '../../mixin/reflection'

module AMA
  module Entity
    class Mapper
      module API
        module Default
          # Default attribute injector
          class Injector < API::Injector
            include Mixin::Reflection

            INSTANCE = new

            # @param [Object] entity
            # @param [AMA::Entity::Mapper::Type] _type
            # @param [AMA::Entity::Mapper::Type::Attribute] attribute
            # @param [Object] value
            # @param [AMA::Entity::Mapper::Context] _context
            def inject(entity, _type, attribute, value, _context = nil)
              set_object_attribute(entity, attribute.name, value)
              entity
            end
          end
        end
      end
    end
  end
end
