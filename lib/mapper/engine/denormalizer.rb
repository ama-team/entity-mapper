# frozen_string_literal: true

require_relative '../mixin/errors'
require_relative '../context'

module AMA
  module Entity
    class Mapper
      class Engine
        # Denormalization entrypoint, a class accepting wildcard denormalization
        # requests (opposed to specific child classes).
        class Denormalizer
          include ::AMA::Entity::Mapper::Mixin::Errors

          def denormalize(source, target_type, context = nil)
            context ||= Context.new
            denormalizer = target_type.denormalizer
            denormalizer.denormalize(source, target_type, context)
          rescue StandardError => e
            raise_if_internal(e)
            message = "Error while denormalizing #{target_type} " \
              "out of #{source.class}"
            mapping_error(message, parent: e, context: context)
          end
        end
      end
    end
  end
end
