# frozen_string_literal: true

require_relative '../mixin/errors'
require_relative 'denormalizer/entity'
require_relative 'denormalizer/enumerable'
require_relative 'denormalizer/object'
require_relative 'denormalizer/primitive'
require_relative 'context'

module AMA
  module Entity
    class Mapper
      class Engine
        # Denormalization entrypoint, a class accepting wildcard denormalization
        # requests (opposed to specific child classes).
        class Denormalizer
          include ::AMA::Entity::Mapper::Mixin::Errors

          def initialize(registry)
            @stack = [
              Primitive.new,
              Entity.new(registry),
              Enumerable.new,
              Object.new
            ]
          end

          def denormalize(source, target_type, context = nil)
            context ||= Context.new
            implementation = @stack.find do |denormalizer|
              denormalizer.supports(target_type)
            end
            implementation.denormalize(source, context, target_type)
          rescue StandardError => e
            message = "Error while denormalizing #{target_type} " \
              "out of #{source.class} (path: #{context.path})"
            mapping_error(message, e)
          end
        end
      end
    end
  end
end
