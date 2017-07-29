# frozen_string_literal: true

require_relative '../injector'
require_relative '../../context'
require_relative '../../mixin/reflection'
require_relative '../../path/segment'

module AMA
  module Entity
    class Mapper
      module API
        module Default
          # Default attribute enumerator
          class Enumerator < API::Injector
            include Mixin::Reflection

            INSTANCE = new

            # @param [Object] entity
            # @param [AMA::Entity::Mapper::Type] type
            # @param [AMA::Entity::Mapper::Context] _context
            def enumerate(entity, type, _context = nil)
              ::Enumerator.new do |yielder|
                type.attributes.values.reject(&:virtual).each do |attribute|
                  next unless object_variable_exists(entity, attribute.name)
                  value = object_variable(entity, attribute.name)
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
