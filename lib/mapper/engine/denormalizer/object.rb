# frozen_string_literal: true

require_relative '../../exception/mapping_error'
require_relative '../../../../lib/mapper/mixin/reflection'

module AMA
  module Entity
    class Mapper
      class Engine
        class Denormalizer
          # Denormalizer for non-standard objects not registered as entities
          class Object
            include ::AMA::Entity::Mapper::Mixin::Reflection
            include ::AMA::Entity::Mapper::Mixin::Errors

            def supports(*)
              true
            end

            # @param [Object] source
            # @param [AMA::Entity::Mapper::Engine::Context] context
            # @param [AMA::Entity::Mapper::Type::Concrete] target_type
            def denormalize(source, context, target_type)
              return source if source.is_a?(target_type.type)
              handler = compute_handler(target_type, context)
              return target_type.type.send(handler, source, context) if handler
              unless source.is_a?(Hash)
                message = "Can't denormalize object #{target_type} " \
                  "from anything but Hash, #{source.class} given"
                mapping_error(message, nil)
              end
              entity = target_type.instantiate
              populate_object(entity, source)
              entity
            end

            private

            def compute_handler(target_type, context)
              handler = context.denormalization_method
              handler && target_type.type.respond_to?(handler) ? handler : nil
            end
          end
        end
      end
    end
  end
end
