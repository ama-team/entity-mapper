# frozen_string_literal: true

module AMA
  module Entity
    class Mapper
      # Wrapper for simple array. Helps to understand where exactly processing
      # is taking place.
      class Path
        attr_reader :stack

        def initialize(stack = [])
          @stack = stack
        end

        %i[attribute index key].each do |category|
          define_method category do |id|
            push(category, id)
          end
        end

        def empty?
          @stack.empty?
        end

        def pop
          self.class.new(stack[0..-1])
        end

        def current
          @stack.last
        end

        def each
          @stack.each do |item|
            yield(item)
          end
        end

        def reduce(carrier)
          @stack.reduce(carrier) do |inner_carrier, item|
            yield(inner_carrier, item)
          end
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
          self.class.new(stack.clone.push(payload))
        end
      end
    end
  end
end
