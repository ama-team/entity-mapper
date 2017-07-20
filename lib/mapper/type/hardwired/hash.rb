# frozen_string_literal: true

require_relative '../concrete'
require_relative '../../path/segment'
require_relative '../../mixin/errors'

module AMA
  module Entity
    class Mapper
      class Type
        module Hardwired
          # Predefined type for Hash class
          class Hash < Concrete
            include Mixin::Errors

            def initialize
              super(::Hash)
              attribute!(:_key, parameter!(:K), virtual: true)
              attribute!(:_value, parameter!(:V), virtual: true)
            end

            def mapper
              lambda do |entity, *, &block|
                result = {}
                entity.each do |key, value|
                  segment = Segment.index(key)
                  new_key = block.call(attributes[:_key], key, segment)
                  new_value = block.call(attributes[:_value], value, segment)
                  result[new_key] = new_value
                end
                result
              end
            end

            def normalizer
              lambda do |entity, *|
                entity
              end
            end

            def denormalizer
              lambda do |input, context, *|
                input = input.to_h if input.respond_to?(:to_h)
                message = "Expected to receive hash, #{input.class} received"
                mapping_error(message, context: context)
              end
            end
          end
        end
      end
    end
  end
end
