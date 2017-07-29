# frozen_string_literal: true

require_relative 'path/segment'

module AMA
  module Entity
    class Mapper
      # Wrapper for simple array. Helps to understand where exactly processing
      # is taking place.
      class Path
        attr_reader :segments

        def initialize(stack = [])
          @segments = stack
        end

        def empty?
          @segments.empty?
        end

        # @param [String, Symbol, Integer] name
        # @return [AMA::Entity::Mapper::Path]
        def index(name)
          push(Segment.index(name))
        end

        # @param [String, Symbol] name
        # @return [AMA::Entity::Mapper::Path]
        def attribute(name)
          push(Segment.attribute(name))
        end

        # @param [String, Symbol] name
        # @return [AMA::Entity::Mapper::Path]
        def property(name)
          push(Segment.property(name))
        end

        # @param [Array<AMA::Entity::Mapper::Path::Segment>] segments
        # @return [AMA::Entity::Mapper::Path]
        def push(*segments)
          segments = segments.map do |segment|
            next segment if segment.is_a?(Segment)
            Segment.attribute(segment)
          end
          self.class.new(@segments + segments)
        end

        # @return [AMA::Entity::Mapper::Path]
        def pop
          self.class.new(@segments[0..-2])
        end

        # @return [AMA::Entity::Mapper::Path::Segment]
        def current
          @segments.last
        end

        def each
          @segments.each do |item|
            yield(item)
          end
        end

        def reduce(carrier)
          @segments.reduce(carrier) do |inner_carrier, item|
            yield(inner_carrier, item)
          end
        end

        # @param [AMA::Entity::Mapper::Path] path
        # @return [AMA::Entity::Mapper::Path]
        def merge(path)
          push(*path.segments)
        end

        def size
          @segments.size
        end

        def segments
          @segments.clone
        end

        # @return [Array<AMA::Entity::Mapper::Path::Segment>]
        def to_a
          @segments.clone
        end

        # @return [String]
        def to_s
          "$#{@segments.join}"
        end
      end
    end
  end
end
