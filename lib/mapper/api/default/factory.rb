# frozen_string_literal: true

require_relative '../factory'
require_relative '../../mixin/errors'
require_relative '../../path/segment'

module AMA
  module Entity
    class Mapper
      module API
        module Default
          # Default entity factory
          class Factory < API::Factory
            include Mixin::Errors

            INSTANCE = new

            # @param [AMA::Entity::Mapper::Type] type
            # @param [Object] _data
            # @param [AMA::Entity::Mapper::Context] context
            def create(type, _data, context)
              create_internal(type)
            rescue StandardError => e
              message = "Failed to instantiate #{type} directly from class"
              if e.is_a?(ArgumentError)
                message += '. Does it have parameterless #initialize() method?'
              end
              mapping_error(message, parent: e, context: context)
            end

            private

            def create_internal(type)
              entity = type.type.new
              type.attributes.values.each do |attribute|
                next if attribute.default.nil? || attribute.virtual
                segment = Path::Segment.attribute(attribute.name)
                value = attribute.default
                type.injector.inject(entity, type, attribute, value, segment)
              end
              entity
            end
          end
        end
      end
    end
  end
end
