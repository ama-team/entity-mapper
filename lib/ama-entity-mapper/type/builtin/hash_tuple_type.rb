# frozen_string_literal: true

require_relative '../../type'
require_relative '../aux/hash_tuple'

module AMA
  module Entity
    class Mapper
      class Type
        module BuiltIn
          # Pair class definition
          class HashTupleType < Type
            def initialize
              super(Aux::HashTuple, virtual: true)

              attribute!(:key, parameter!(:K))
              attribute!(:value, parameter!(:V))

              enumerator_block do |entity, type, *|
                ::Enumerator.new do |yielder|
                  yielder << [type.attributes[:key], entity.key, nil]
                  yielder << [type.attributes[:value], entity.value, nil]
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
