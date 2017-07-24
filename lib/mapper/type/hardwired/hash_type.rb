# frozen_string_literal: true

require_relative '../concrete'
require_relative '../../path/segment'
require_relative '../../mixin/errors'
require_relative 'pair_type'
require_relative '../aux/pair'

module AMA
  module Entity
    class Mapper
      class Type
        module Hardwired
          # Predefined type for Hash class
          class HashType < Concrete
            include Mixin::Errors

            def initialize
              super(::Hash)
              define_attribute
              define_enumerator
              define_acceptor
              define_extractor
              define_normalizer
              define_denormalizer
            end

            private

            def define_attribute
              type = PairType.new
              type = type.resolve(
                type.parameter!(:L) => parameter!(:K),
                type.parameter!(:R) => parameter!(:V)
              )
              attribute!(:_tuple, type, virtual: true)
            end

            def define_acceptor
              acceptor_factory = lambda do |entity, *|
                acceptor = Object.new
                acceptor.define_singleton_method(:accept) do |_, tuple, *|
                  entity[tuple.left] = tuple.right
                end
                acceptor
              end
              self.acceptor = acceptor_factory
            end

            def define_enumerator
              self.enumerator = lambda do |entity, type, *|
                ::Enumerator.new do |yielder|
                  entity.each do |key, value|
                    tuple = Aux::Pair.new(left: key, right: value)
                    attribute = type.attributes[:_tuple]
                    yielder << [attribute, tuple, Path::Segment.index(key)]
                  end
                end
              end
            end

            def define_extractor
              self.extractor = lambda do |source, type, context = nil, *|
                source = source.to_h if source.respond_to?(:to_h)
                unless source.is_a?(Hash)
                  message = "Expected to receive hash, #{source.class} received"
                  mapping_error(message, context: context)
                end
                ::Enumerator.new do |yielder|
                  source.each do |key, value|
                    tuple = Aux::Pair.new(left: key, right: value)
                    attribute = type.attributes[:_tuple]
                    yielder << [attribute, tuple, Path::Segment.index(key)]
                  end
                end
              end
            end

            def define_denormalizer
              self.denormalizer = lambda do |input, context, *|
                input = input.to_h if input.respond_to?(:to_h)
                return input.clone if input.is_a?(Hash)
                message = "Expected to receive hash, #{input.class} received"
                mapping_error(message, context: context)
              end
            end

            def define_normalizer
              self.normalizer = lambda do |entity, *|
                entity.clone
              end
            end

            INSTANCE = new
          end
        end
      end
    end
  end
end
