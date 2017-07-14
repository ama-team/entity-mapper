# frozen_string_literal: true

require_relative '../../exception/mapping_error'
require_relative '../../mixin/reflection'
require_relative '../../mixin/errors'

module AMA
  module Entity
    class Mapper
      class Engine
        class Denormalizer
          # Denormalizer for non-standard objects not registered as entities
          class Enumerable
            include ::AMA::Entity::Mapper::Mixin::Reflection
            include ::AMA::Entity::Mapper::Mixin::Errors

            # @param [AMA::Entity::Mapper::Type::Concrete] type
            def supports(type)
              type.included_modules.include?(::Enumerable)
            end

            # @param [Object] source
            # @param [AMA::Entity::Mapper::Engine::Context] _context
            # @param [AMA::Entity::Mapper::Type::Concrete] target_type
            def denormalize(source, _context, target_type)
              return source if source.is_a?(target_type.type)
              target_type.type.new(source)
            rescue ArgumentError => e
              message = "Failed to instantiate #{target_type}: #{e.message}." \
                'Does it follow standard convention accepting enumerable as ' \
                '#initialize() argument?'
              mapping_error(message, nil)
            rescue StandardError => e
              mapping_error("Failed to instantiate #{target_type}", e)
            end

            private

            def disassemble(object)
              intermediate = object.instance_variables.map do |variable|
                [variable[1..-1].to_sym, object.instance_variable_get(variable)]
              end
              Hash[intermediate]
            end

            def instantiate(type)
              type.type.new
            rescue ArgumentError => e
              message = "Failed to instantiate object of type #{type}: " \
                "#{e.message}. Have you passed class with " \
                'mandatory parameters in #initialize method?'
              mapping_error(message, nil)
            rescue StandardError => e
              message = "Failed to instantiate object of type #{type}"
              mapping_error(message, e)
            end
          end
        end
      end
    end
  end
end
