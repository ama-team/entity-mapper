# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/type/hardwired/hash_tuple_type'
require_relative '../../../../../../lib/mapper/type/aux/hash_tuple'

klass = ::AMA::Entity::Mapper::Type::Hardwired::HashTupleType
tuple_class = ::AMA::Entity::Mapper::Type::Aux::HashTuple

describe klass do
  let(:tuple) do
    tuple_class.new(key: :key, value: :value)
  end

  let(:type) do
    klass::INSTANCE
  end

  let(:context) do
    double
  end

  describe '#enumerator' do
    it 'enumerates key and value attributes without path segment' do
      proc = lambda do |listener|
        type.enumerator.enumerate(tuple, type, context).each(&listener)
      end
      expectation = [
        [type.attributes[:key], tuple.key, nil],
        [type.attributes[:value], tuple.value, nil],
      ]
      expect(&proc).to yield_successive_args(*expectation)
    end
  end
end
