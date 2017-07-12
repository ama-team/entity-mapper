# frozen_string_literal: true

module AMA
  module Entity
    class Mapper
      # Wrapper for simple array. Helps to understand where exactly processing
      # is taking place.
      class Path
        attr_reader :stack

        def initialize
          @stack = []
        end

        %i[attribute index key].each do |category|
          define_method category do |id|
            push(category, id)
          end
        end

        def pop
          @stack.pop
        end

        def current
          @stack.last
        end

        def to_s
          parts = stack.map do |item|
            next "##{item[:id]}" if item[:type] == :attribute
            next "[#{item[:id]}]" if item[:type] == :index
            ".#{item[:id]}"
          end
          "$#{parts.join}"
        end

        private

        def push(type, id)
          payload = { type: type, id: id }
          @stack.push(payload)
        end
      end
    end
  end
end
