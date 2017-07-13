# frozen_string_literal: true

require_relative 'context'
require_relative '../exception/mapping_error'
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
          def initialize(registry)
            @registry = registry
            @stack = [
              ::AMA::Entity::Mapper::Engine::Normalizer::Primitive.new,
              ::AMA::Entity::Mapper::Engine::Normalizer::Enumerable.new,
              ::AMA::Entity::Mapper::Engine::Normalizer::Entity.new(registry),
              ::AMA::Entity::Mapper::Engine::Normalizer::Object.new
            ]
          end

          def normalize(value, context = nil, target_type = nil)
            context ||= Context.new
            normalizer = @stack.find { |candidate| candidate.supports(value) }
            normalizer.normalize(value, context, target_type)
          rescue StandardError => e
            message = "Error while normalizing #{value.class} " \
              "at #{context.path}: #{e.message}"
            mapping_error(message)
          end

          def normalize_recursively(value, context = nil, target_type = nil)
            context ||= Context.new
            data = normalize(value, context, target_type)
            if data.is_a?(Enumerable)
              return data.map_with_index do |item, index|
                normalize_recursively(item, context.advance(:index, index))
              end
            end
            return data unless data.is_a?(Hash)
            intermediate = data.map do |key, item|
              [key, normalize_recursively(item, context.advance(:key, key))]
            end
            Hash[intermediate]
          end

          private

          def mapping_error(message)
            raise ::AMA::Entity::Mapper::Exception::MappingError, message
          end
        end
      end
    end
  end
end
