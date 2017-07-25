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
            # @param [AMA::Entity::Mapper::Context] context
            def enumerate(entity, type, context = nil)
              context ||= Context.new
              ::Enumerator.new do |yielder|
                type.attributes.each do |attribute|
                  value = object_variable(entity, attribute.name)
                  segment = Path::Segment.attribute(attribute.name)
                  yielder << [attribute, value, context.advance(segment)]
                end
              end
            end
          end
        end
      end
    end
  end
end
