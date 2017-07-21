# frozen_string_literal: true

require_relative '../../../../lib/mapper/mixin/reflection'
require_relative '../../../../lib/mapper/mixin/errors'

module AMA
  module Entity
    class Mapper
      class Engine
        class Denormalizer
          # Standard-interface entity denormalizer
          class Entity
            include ::AMA::Entity::Mapper::Mixin::Reflection
            include ::AMA::Entity::Mapper::Mixin::Errors

            def initialize(registry)
              @registry = registry
            end

            # @param [AMA::Entity::Mapper::Type::Concrete] type
            def supports(type)
              @registry.registered?(type.type)
            end

            # @param [Object] value
            # @param [AMA::Entity::Mapper::Engine::Context] context
            # @param [AMA::Entity::Mapper::Type::Concrete] target_type
            def denormalize(value, context, target_type)
              return value if value.is_a?(target_type.type)
              denormalizer = target_type.denormalizer
              unless denormalizer
                return denormalize_entity(value, context, target_type)
              end
              denormalizer.call(value, context, target_type) do |processed|
                denormalize_entity(processed, context, target_type)
              end
            end

            private

            def denormalize_entity(structure, context, target_type)
              unless structure.is_a?(Hash)
                message = "Can't denormalize #{target_type} from " \
                  "anything but hash (#{structure.class} supplied)"
                mapping_error(message, context: context)
              end
              entity = target_type.factory.create(context, structure)
              attributes = target_type.attributes.values
              attributes = filter_attributes(attributes, structure)
              extracted_attributes = extract_attributes(structure, attributes)
              # TODO: use acceptor
              set_object_attributes(entity, extracted_attributes)
            end

            def filter_attributes(attributes, structure)
              attributes.reject do |attribute|
                next true if attribute.virtual
                name = attribute.name
                !structure.key?(name) && !structure.key?(name.to_s)
              end
            end

            def extract_attributes(structure, attributes)
              # TODO: add attribute denormalizer support
              intermediate = attributes.map do |attribute|
                name = attribute.name
                value = structure.fetch(name, nil)
                value ||= structure.fetch(name.to_s, nil)
                [name, value]
              end
              Hash[intermediate]
            end
          end
        end
      end
    end
  end
end
