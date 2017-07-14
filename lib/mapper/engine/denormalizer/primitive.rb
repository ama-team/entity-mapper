# frozen_string_literal: true

require_relative '../../exception/mapping_error'

module AMA
  module Entity
    class Mapper
      class Engine
        class Denormalizer
          # Standard-interface denormalizer for denormalizing primitives.
          class Primitive
            MAPPING = {
              String => [],
              Symbol => [:to_sym],
              Numeric => %i[to_f to_i],
              TrueClass => [:to_bool],
              FalseClass => [:to_bool],
              Array => [:to_a],
              Hash => [:to_h]
            }.freeze

            # @param [AMA::Entity::Mapper::Type::Concrete] type
            def supports(type)
              !downgrade_klass(type.type).nil?
            end

            # @param [Object] value
            # @param [AMA::Entity::Mapper::Engine::Context] _context
            # @param [AMA::Entity::Mapper::Type::Concrete] target_type
            def denormalize(value, _context, target_type)
              return value if value.is_a?(target_type.type)
              methods = MAPPING[downgrade_klass(target_type.type)]
              methods.each do |method|
                next unless value.respond_to?(method)
                begin
                  result = value.send(method)
                rescue ArgumentError
                  next
                end
                return result if result.is_a?(target_type.type)
              end
              message = "Can't denormalize #{target_type} out of #{value.class}"
              mapping_error(message)
            end

            private

            def downgrade_klass(klass)
              klass.ancestors.find do |ancestor|
                MAPPING.key?(ancestor)
              end
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
