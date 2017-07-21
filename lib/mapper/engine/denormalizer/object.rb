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
              entity = target_type.factory.create(context, source)
              extractor = target_type.extractor(source)
              acceptor = target_type.acceptor(entity, context)
              extractor.each do |attribute, value, segment = nil|
                acceptor.accept(attribute, value, segment)
              end
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
