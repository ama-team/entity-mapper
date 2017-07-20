# frozen_string_literal: true

require_relative '../concrete'
require_relative '../../path/segment'

module AMA
  module Entity
    class Mapper
      class Type
        module Hardwired
          # Default Enumerable handler
          class Enumerable < Concrete
            def initialize
              super(::Enumerable)
              attribute = attribute!(:_value, parameter!(:T), virtual: true)

              self.normalizer = lambda do |input, *|
                input.map(&:itself)
              end

              self.denormalizer = lambda do |entity, *|
                entity
              end

              self.mapper = lambda do |entity, *, &block|
                entity.map_with_index do |item, index|
                  block.call(attribute, item, Segment.index(index))
                end
              end
            end
          end
        end
      end
    end
  end
end
