# frozen-string_literal: true

require_relative '../../exception/mapping_error'

module AMA
  module Entity
    class Mapper
      class Engine
        class Normalizer
          # Special normalizer for registered entities
          class Entity
            def initialize(registry)
              @registry = registry
            end

            def normalize(entity, context = nil, target_type = nil)
              type = @registry.find!(entity.class)
              unless type.normalizer
                return normalize_entity(entity, context, target_type)
              end
              type.normalizer.call(entity, context, target_type) do |handle|
                normalize_entity(handle, context, target_type)
              end
            rescue StandardError => e
              message = 'Error while normalizing entity ' \
                "of type #{entity.class}: #{e.message}"
              mapping_error(message)
            end

            def supports(value)
              @registry.include?(value.class)
            end

            private

            def normalize_entity(entity, *)
              type = @registry.find!(entity.class)
              type.attributes.values.each_with_object({}) do |attribute, values|
                next values if attribute.sensitive || attribute.virtual
                values[attribute.name] = normalize_attribute(entity, attribute)
                values
              end
            end

            def normalize_attribute(entity, attribute)
              # TODO: add attribute normalizer support
              entity.instance_variable_get("@#{attribute.name}")
            end

            # @param [String] message
            def mapping_error(message)
              raise ::AMA::Entity::Mapper::Exception::MappingError, message
            end
          end
        end
      end
    end
  end
end
