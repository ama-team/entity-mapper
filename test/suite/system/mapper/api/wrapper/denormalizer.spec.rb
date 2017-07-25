# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/api/wrapper/denormalizer'
require_relative '../../../../../../lib/mapper/exception/mapping_error'

klass = ::AMA::Entity::Mapper::API::Wrapper::Denormalizer
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError

describe klass do
  let(:attribute) do
    double(name: :id)
  end

  let(:type) do
    double(type: double, attributes: { id: attribute })
  end

  let(:entity) do
    double
  end

  let(:input) do
    { id: :jeff }
  end

  describe '#denormalize' do
    it 'should provide fallback method' do
      denormalizer = double
      expect(denormalizer).to receive(:denormalize).exactly(:once) do |&block|
        block.call(entity, input, type)
      end
      klass.new(denormalizer).denormalize(entity, input, type)
    end

    it 'should wrap exceptions in mapping error' do
      denormalizer = double
      expect(denormalizer).to receive(:denormalize).exactly(:once).and_raise
      proc = lambda do
        klass.new(denormalizer).denormalize(entity, input, type)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'should provide informational message about method signature' do
      denormalizer = double
      expect(denormalizer).to(
        receive(:denormalize).exactly(:once).and_raise(ArgumentError)
      )
      proc = lambda do
        klass.new(denormalizer).denormalize(entity, input, type)
      end
      regexp = /signature|interface|contract/i
      expect(&proc).to raise_error(mapping_error_class, regexp)
    end
  end
end
