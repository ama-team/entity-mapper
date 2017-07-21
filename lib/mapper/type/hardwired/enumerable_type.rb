# frozen_string_literal: true

require_relative '../concrete'
require_relative '../../path/segment'

module AMA
  module Entity
    class Mapper
      class Type
        module Hardwired
          # Default Enumerable handler
          class EnumerableType < Concrete
            def initialize
              super(::Enumerable)
              attribute!(:_value, parameter!(:T), virtual: true)

              define_normalizer
              define_denormalizer
              define_enumerator
              define_acceptor
              define_extractor
            end

            private

            def define_normalizer
              self.normalizer = lambda do |input, *|
                input.map(&:itself)
              end
            end

            def define_denormalizer
              self.denormalizer = lambda do |entity, *|
                entity
              end
            end

            def value_attribute
              attributes[:_value]
            end

            def define_enumerator
              attribute = value_attribute
              self.enumerator = lambda do |entity, *|
                ::Enumerator.new do |yielder|
                  entity.each_with_index do |value, index|
                    yielder << [attribute, value, Path::Segment.index(index)]
                  end
                end
              end
            end

            def define_acceptor
              self.acceptor = lambda do |entity, *|
                acceptor = Object.new
                acceptor.define_singleton_method(:accept) do |_, value, segment|
                  entity[segment.name] = value
                end
                acceptor
              end
            end

            def define_extractor
              attribute = attributes[:_value]
              self.extractor = lambda do |object, _type, context = nil, *|
                unless object.is_a?(::Enumerable)
                  message = "Expected enumerable, got #{object.class}"
                  mapping_error(message, context: context)
                end
                ::Enumerator.new do |yielder|
                  object.each_with_index do |value, index|
                    yielder << [attribute, value, Path::Segment.index(index)]
                  end
                end
              end
            end

            INSTANCE = new
          end
        end
      end
    end
  end
end
