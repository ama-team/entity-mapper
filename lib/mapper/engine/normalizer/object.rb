# frozen_string_literal: true

require_relative '../context'
require_relative '../../exception/mapping_error'

module AMA
  module Entity
    class Mapper
      class Engine
        class Normalizer
          # Fallback normalizer for any object possible object
          class Object
            def supports(*)
              true
            end

            def normalize(value, context = nil, *)
              context ||= ::AMA::Entity::Mapper::Engine::Context.new
              handler = compute_handler(value, context)
              return value.send(handler) if handler
              intermediate = value.instance_variables.map do |variable|
                [variable[1..-1].to_sym, value.instance_variable_get(variable)]
              end
              Hash[intermediate]
            rescue StandardError => e
              message = "Exception while trying to denormalize #{value.class}" \
                " as standard object: #{e.message}"
              mapping_error(message)
            end

            private

            def compute_handler(value, context)
              handler = context.normalization_method
              handler ? value.respond_to?(handler) : nil
            end

            def mapping_error(message)
              raise ::AMA::Entity::Mapper::Exception::MappingError, message
            end
          end
        end
      end
    end
  end
end
