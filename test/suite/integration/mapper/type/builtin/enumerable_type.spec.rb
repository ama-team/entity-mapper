# frozen_string_literal: true

require_relative '../../../../../../lib/ama-entity-mapper/type/builtin/enumerable_type'
require_relative '../../../../../../lib/ama-entity-mapper/path/segment'
require_relative '../../../../../../lib/ama-entity-mapper/error/mapping_error'

klass = ::AMA::Entity::Mapper::Type::BuiltIn::EnumerableType
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

  describe '#factory' do
    it 'provides array factory' do
      expect(type.factory.create(type, double, context)).to eq([])
    end
  end

  describe '#normalizer' do
    it 'should provide convert-to-array normalizer' do
      data = [1, 2, 3]
      expect(type.normalizer.normalize(data, type, context)).to eq(data)
    end
  end

  describe '#denormalizer' do
    it 'should provide pass-through denormalizer' do
      data = [1, 2, 3]
      expect(type.denormalizer.denormalize(data, type, context)).to eq(data)
    end

    it 'raises if Hash is provided' do
      proc = lambda do
        type.denormalizer.denormalize({}, type, context)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'raises if non-Enumerable type is provided' do
      proc = lambda do
        type.denormalizer.denormalize(double, type, context)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end
  end

  describe '#enumerator' do
    it 'provides default enumerator' do
      source = [1, 2, 3]
      attribute = type.attributes[:_value]
      proc = lambda do |consumer|
        type.enumerator.enumerate(source, type, context).each(&consumer)
      end
      expectations = source.each_with_index.map do |item, index|
        [attribute, item, segment_class.index(index)]
      end
      expect(&proc).to yield_successive_args(*expectations)
    end
  end

  describe '#injector' do
    it 'should provide default injector' do
      target = []
      expectation = [1, 2, 3]
      attribute = type.attributes[:_value]
      expectation.each_with_index.map do |value, index|
        segment = segment_class.index(index)
        context = double(path: double(current: segment))
        type.injector.inject(target, type, attribute, value, context)
      end
      expect(target).to eq(expectation)
    end
  end
end
