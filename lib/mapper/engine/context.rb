# frozen_string_literal: true

require_relative '../path'

module AMA
  module Entity
    class Mapper
      class Engine
        # Normalization/denormalization context. Holds current path relatively
        # to processed item and some options.
        class Context
          DEFAULTS = {
            path: Path.new,
            normalization_method: :normalize,
            denormalization_method: :denormalize
          }.freeze

          # @!attribute path
          #   @return [Path]
          attr_reader :path
          attr_reader :normalization_method
          attr_reader :denormalization_method

          def initialize(**options)
            DEFAULTS.each do |key, default|
              instance_variable_set("@#{key}", options.fetch(key, default))
            end
          end

          def advance(type, key)
            data = to_h.merge({ path: path.send(type,key )})
            self.class.new(**data)
          end

          def to_h
            intermediate = DEFAULTS.keys.map do |key|
              [key, instance_variable_get("@#{key}")]
            end
            Hash[intermediate]
          end

          FORBIDDING = new(
            normalization_method: nil,
            denormalization_method: nil
          )
        end
      end
    end
  end
end
