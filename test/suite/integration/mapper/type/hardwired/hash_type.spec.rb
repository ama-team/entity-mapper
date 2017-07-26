# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/type/hardwired/hash_type'
require_relative '../../../../../../lib/mapper/type/aux/pair'
require_relative '../../../../../../lib/mapper/exception/mapping_error'
require_relative '../../../../../../lib/mapper/path/segment'

klass = ::AMA::Entity::Mapper::Type::Hardwired::HashType
pair_class = ::AMA::Entity::Mapper::Type::Aux::Pair
segment_class = ::AMA::Entity::Mapper::Path::Segment
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError

describe klass do
  let(:type) do
    klass::INSTANCE
  end

  describe '#enumerator' do
    it 'should correctly enumerate provided hash' do
      source = { id: 12 }
      proc = lambda do |block|
        type.enumerator.enumerate(source, type).each(&block)
      end
      pair = pair_class.new(left: :id, right: 12)
      attribute = type.attributes[:_tuple]
      expect(&proc).to yield_with_args([attribute, pair, anything])
    end
  end

  describe '#injector' do
    it 'should provide correctly-behaving acceptor' do
      object = {}
      tuple = pair_class.new(left: :key, right: :value)
      expectation = { key: :value }
      segment = segment_class.index(:key)
      type.injector.inject(object, type, type.attributes[:_tuple], tuple, segment)
      expect(object).to eq(expectation)
    end
  end

  describe '#denormalizer' do
    it 'should return denormalizer capable to denormalize hashes' do
      data = { x: 12 }
      expect(type.denormalizer.denormalize(data, type)).to eq(data)
    end

    it 'should return denormalizer capable to denormalize :to_h result' do
      data = { x: 12 }
      source = Object.new
      source.define_singleton_method(:to_h) do
        data
      end
      expect(type.denormalizer.denormalize(source, type)).to eq(data)
    end

    it 'should return denormalizer intolerant to non-hash input' do
      proc = lambda do
        type.denormalizer.denormalize(double, type)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end
  end

  describe '#normalizer' do
    it 'should return pass-through normalizer' do
      data = { x: 12 }
      expect(type.normalizer.normalize(data, type)).to eq(data)
    end
  end
end
