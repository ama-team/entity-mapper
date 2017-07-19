# frozen_string_literal: true

require_relative '../path'
require_relative '../context'

module AMA
  module Entity
    class Mapper
      class Engine
        # Normalization/denormalization context. Holds current path relatively
        # to processed item and some options.
        # TODO: rename class for clarity
        class Context < Mapper::Context
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

          # Creates new context, resembling traversal to specified segment
          #
          # @param [AMA::Entity::Mapper::Path::Segment, String, Symbol] segment
          # @return [AMA::Entity::Mapper::Context]
          def advance(segment)
            data = to_h.merge(path: path.push(segment))
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
