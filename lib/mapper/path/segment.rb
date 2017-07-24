# frozen_string_literal: true

module AMA
  module Entity
    class Mapper
      class Path
        # Well, that's quite self-explanatory. Path consists of segments, and
        # here's one.
        class Segment
          attr_reader :name
          attr_reader :prefix
          attr_reader :suffix

          def initialize(name, prefix = nil, suffix = nil)
            @name = name
            @prefix = prefix
            @suffix = suffix
          end

          def to_s
            "#{@prefix}#{@name}#{@suffix}"
          end

          def hash
            @name.hash ^ @prefix.hash ^ @suffix.hash
          end

          def eql?(other)
            return false unless other.is_a?(self.class)
            @name == other.name && @prefix == other.prefix &&
              @suffix == other.suffix
          end

          def ==(other)
            eql?(other)
          end

          class << self
            def attribute(name)
              new(name, '#')
            end

            def property(name)
              new(name, '.')
            end

            def index(name)
              new(name, '[', ']')
            end
          end
        end
      end
    end
  end
end
