# frozen_string_literal: true

require_relative 'context'
require_relative '../mixin/errors'
require_relative 'normalizer/entity'
require_relative 'normalizer/object'
require_relative 'normalizer/primitive'
require_relative 'normalizer/enumerable'

module AMA
  module Entity
    class Mapper
      class Engine
        # Class for conversion of any passed structure down to basic primitives
        # - strings, hashes, etc.
        class Normalizer
          include Mixin::Errors

          def initialize(registry)
            @registry = registry
            @stack = [
              Primitive.new,
              Enumerable.new,
              Entity.new(registry),
              Object.new
            ]
          end

          def normalize(value, context = nil, target_type = nil)
            context ||= Context.new
            normalizer = @stack.find { |candidate| candidate.supports(value) }
            normalizer.normalize(value, context, target_type)
          rescue StandardError => e
            raise_if_internal(e)
            message = "Error while normalizing #{value.class} " \
              "at #{context.path}: #{e.message}"
            mapping_error(message, context: context)
          end
        end
      end
    end
  end
end
