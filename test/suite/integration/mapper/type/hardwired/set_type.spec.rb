# frozen_string_literal: true

require 'set'

require_relative '../../../../../../lib/mapper/type/hardwired/set_type'
require_relative '../../../../../../lib/mapper/exception/mapping_error'

klass = ::AMA::Entity::Mapper::Type::Hardwired::SetType
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError
type = klass::INSTANCE

describe klass do
  describe 'factory' do
    it 'just provides empty set' do
      expect(type.factory.create(type, nil, nil)).to eq(Set.new([]))
    end
  end

  describe '#denormalizer' do
    it 'provides array denormalizer' do
      data = [1, 2, 3]
      expectation = Set.new(data)
      expect(type.denormalizer.denormalize(data, type)).to eq(expectation)
    end

    it 'raises if Hash is denormalized' do
      proc = lambda do
        type.denormalizer.denormalize({}, type)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'raises if non-Enumerable is denormalized' do
      proc = lambda do
        type.denormalizer.denormalize(double, type)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end
  end

  describe '#normalizer' do
    it 'normalizes Set to Array' do
      data = [1, 2, 3]
      expectation = Set.new(data)
      expect(type.normalizer.normalize(expectation, type)).to eq(data)
    end
  end

  describe '#injector' do
    it 'injects values into Set' do
      set = Set.new([])
      data = [1, 2, 3]
      data.each do |number|
        type.injector.inject(set, type, double, number, double)
      end
      expect(set).to eq(Set.new(data))
    end
  end

  describe '#enumerator' do
    it 'enumerates set elements' do
      value = 1
      set = Set.new([value])
      proc = lambda do |block|
        type.enumerator.enumerate(set, type, double).each(&block)
      end
      attribute = type.attributes[:_value]
      expect(&proc).to yield_with_args([attribute, value, anything])
    end
  end
end
