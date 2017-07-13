# frozen_String_literal: true

module AMA
  module Entity
    class Mapper
      class Engine
        class Normalizer
          # Special normalizer for enumerable instances
          class Enumerable
            def supports(value)
              value.is_a?(::Enumerable)
            end

            def normalize(value, *)
              value.map(&:itself)
            end
          end
        end
      end
    end
  end
end
