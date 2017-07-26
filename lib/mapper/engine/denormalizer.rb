# frozen_string_literal: true

require_relative '../mixin/errors'
require_relative '../context'

module AMA
  module Entity
    class Mapper
      class Engine
        # Thin denormalization master. Delegates processing to type
        # denormalizer and adds security wrap.
        class Denormalizer
          include ::AMA::Entity::Mapper::Mixin::Errors

          # @param [Object] source
          # @param [AMA::Entity::Mapper::Type] target_type
          # @param [AMA::Entity::Mapper::Context] context
          # @return [Object] Object of target type
          def denormalize(source, target_type, context)
            result = denormalize_internal(source, target_type, context)
            return result if target_type.instance?(result)
            message = "Denormalizer for type #{target_type} has returned " \
              "something that is not an instance of #{target_type}: " \
              "#{result} (#{result.class})"
            compliance_error(message, context: context)
          end

          private

          # @param [Object] source
          # @param [AMA::Entity::Mapper::Type] target_type
          # @param [AMA::Entity::Mapper::Context] context
          # @return [Object] Object of target type
          def denormalize_internal(source, target_type, context)
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
