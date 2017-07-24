# frozen_string_literal: true

require_relative '../../path/segment'
require_relative '../../mixin/errors'
require_relative '../../mixin/reflection'

module AMA
  module Entity
    class Mapper
      class Type
        class Concrete < Type
          # Default implementation for type factory
          class Enumerator < ::Enumerator
            include Mixin::Errors
            include Mixin::Reflection

            # @param [AMA::Entity::Mapper::Type::Concrete] type
            # @param [Object] object
            def initialize(type, object)
              super() do |yielder|
                type.attributes.values.each do |attribute|
                  value = object_variable(object, attribute.name)
                  segment = Path::Segment.attribute(attribute.name)
                  yielder << [attribute, value, segment]
                end
              end
            end
          end
        end
      end
    end
  end
end
