# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/type/builtin/hash_type'
require_relative '../../../../../../lib/mapper/type/aux/hash_tuple'
require_relative '../../../../../../lib/mapper/error/mapping_error'
require_relative '../../../../../../lib/mapper/path/segment'

klass = ::AMA::Entity::Mapper::Type::BuiltIn::HashType
tuple_class = ::AMA::Entity::Mapper::Type::Aux::HashTuple
segment_class = ::AMA::Entity::Mapper::Path::Segment
mapping_error_class = ::AMA::Entity::Mapper::Error::MappingError

describe klass do
  let(:type) do
    klass::INSTANCE
  end

  let(:context) do
    context = double(path: double(current: nil))
    allow(context).to receive(:advance).and_return(context)
    context
  end

  describe '#enumerator' do
    it 'should correctly enumerate provided hash' do
      source = { id: 12 }
      proc = lambda do |block|
        type.enumerator.enumerate(source, type, context).each(&block)
      end
      tuple = tuple_class.new(key: :id, value: 12)
      attribute = type.attributes[:_tuple]
      expect(&proc).to yield_with_args([attribute, tuple, anything])
    end
  end

  describe '#injector' do
    it 'should provide correctly-behaving acceptor' do
      object = {}
      tuple = tuple_class.new(key: :key, value: :value)
      expectation = { key: :value }
      segment = segment_class.index(:key)
      attribute = type.attributes[:_tuple]
      type.injector.inject(object, type, attribute, tuple, segment)
      expect(object).to eq(expectation)
    end
  end

  describe '#denormalizer' do
    it 'should return denormalizer capable to denormalize hashes' do
      data = { x: 12 }
      expect(type.denormalizer.denormalize(data, type, context)).to eq(data)
    end

    it 'should return denormalizer capable to denormalize :to_h result' do
      data = { x: 12 }
      source = Object.new
      source.define_singleton_method(:to_h) do
        data
      end
      expect(type.denormalizer.denormalize(source, type, context)).to eq(data)
    end

    it 'should return denormalizer intolerant to non-hash input' do
      proc = lambda do
        type.denormalizer.denormalize(double, type, context)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end
  end

  describe '#normalizer' do
    it 'should return pass-through normalizer' do
      data = { x: 12 }
      expect(type.normalizer.normalize(data, type, context)).to eq(data)
    end
  end
end
