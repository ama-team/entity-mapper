# frozen_string_literal: true

require_relative '../concrete'
require_relative '../../path/segment'
require_relative '../../mixin/errors'
require_relative '../../mixin/reflection'
require_relative 'hash_tuple_type'
require_relative '../aux/hash_tuple'

module AMA
  module Entity
    class Mapper
      class Type
        module Hardwired
          # Predefined type for Hash class
          class HashType < Concrete
            include Mixin::Errors
            extend Mixin::Errors

            def initialize
              super(::Hash)
              define_attribute
              define_enumerator
              define_injector
              define_normalizer
              define_denormalizer
            end

            private

            def define_attribute
              type = HashTupleType.new
              type = type.resolve(
                type.parameter!(:K) => parameter!(:K),
                type.parameter!(:V) => parameter!(:V)
              )
              attribute!(:_tuple, type, virtual: true)
            end

            def define_enumerator
              enumerator_block do |entity, type, *|
                ::Enumerator.new do |yielder|
                  entity.each do |key, value|
                    tuple = Aux::HashTuple.new(key: key, value: value)
                    attribute = type.attributes[:_tuple]
                    yielder << [attribute, tuple, Path::Segment.index(key)]
                  end
                end
              end
            end

            def define_injector
              injector_block do |entity, _, _, tuple, *|
                entity[tuple.key] = tuple.value
              end
            end

            def define_denormalizer
              denormalizer_block do |input, type, context = nil, *|
                input = input.to_h if input.respond_to?(:to_h)
                break input if input.is_a?(Hash)
                message = "Expected to receive hash, #{input.class} received"
                type.mapping_error(message, context: context)
              end
            end

            def define_normalizer
              normalizer_block do |entity, *|
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
