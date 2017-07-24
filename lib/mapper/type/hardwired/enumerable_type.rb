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

              define_factory
              define_normalizer
              define_denormalizer
              define_enumerator
              define_acceptor
              define_extractor
            end

            private

            def define_factory
              self.factory = Object.new.tap do |factory|
                factory.define_singleton_method(:create) do |*|
                  []
                end
              end
            end

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

            def define_enumerator
              self.enumerator = lambda do |entity, type, *|
                ::Enumerator.new do |yielder|
                  attribute = type.attributes[:_value]
                  entity.each_with_index do |value, index|
                    yielder << [attribute, value, Path::Segment.index(index)]
                  end
                end
              end
            end

            def define_acceptor
              self.acceptor = lambda do |entity, *|
                Object.new.tap do |acceptor|
                  acceptor.define_singleton_method(:accept) do |_, val, segment|
                    entity[segment.name] = val
                  end
                end
              end
            end

            def define_extractor
              self.extractor = lambda do |object, type, context = nil, *|
                unless object.is_a?(::Enumerable)
                  message = "Expected enumerable, got #{object.class}"
                  mapping_error(message, context: context)
                end
                ::Enumerator.new do |yielder|
                  object.each_with_index do |value, index|
                    attribute = type.attributes[:_value]
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
