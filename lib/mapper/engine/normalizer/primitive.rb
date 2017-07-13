# frozen_String_literal: true

module AMA
  module Entity
    class Mapper
      class Engine
        class Normalizer
          # Primitive data structures serializer
          class Primitive
            CLASSES = [
              String,
              Symbol,
              Numeric,
              TrueClass,
              FalseClass,
              Array,
              Hash
            ].freeze

            def supports(value)
              CLASSES.any? do |klass|
                value.is_a?(klass)
              end
            end

            def normalize(value, *)
              value
            end
          end
        end
      end
    end
  end
end
