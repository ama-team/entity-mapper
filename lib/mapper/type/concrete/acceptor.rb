# frozen_string_literal: true

require_relative '../../mixin/reflection'

module AMA
  module Entity
    class Mapper
      class Type
        class Concrete < Type
          # Default implementation for attribute acceptor
          class Acceptor
            include Mixin::Reflection

            # @param [AMA::Entity::Mapper::Type::Concrete] type
            # @param [Object] object
            def initialize(type, object)
              @type = type
              @object = object
            end

            # @param [AMA::Entity::Mapper::Type::Attribute] _attribute
            # @param [Object] value
            # @param [AMA::Entity::Mapper::Path::Segment] segment
            def accept(_attribute, value, segment)
              set_object_attribute(@object, segment.name, value)
            end
          end
        end
      end
    end
  end
end
