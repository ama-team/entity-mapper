# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/handler/entity/denormalizer'
require_relative '../../../../../../lib/mapper/error/mapping_error'
require_relative '../../../../../../lib/mapper/error/compliance_error'

klass = ::AMA::Entity::Mapper::Handler::Entity::Denormalizer
mapping_error_class = ::AMA::Entity::Mapper::Error::MappingError
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError

describe klass do
  let(:denormalizer) do
    klass::INSTANCE
  end

  let(:attributes) do
    {
      value: double(
        name: :value,
        virtual: false
      ),
      virtual: double(
        name: :virtual,
        virtual: true
      )
    }
  end

  let(:attribute_value) do
    double
  end

  let(:segment) do
    double
  end

  let(:entity) do
    double
  end

  let(:type) do
    type = double(
      attributes: attributes,
      factory: double(create: entity),
      enumerator: double(
        enumerate: nil
      )
    )
    allow(type.enumerator).to receive(:enumerate) do
      ::Enumerator.new do |y|
        attributes.each do |attribute|
          y << [attribute, attribute_value, segment]
        end
      end
    end
    type
  end

  let(:context) do
    double(path: nil, advance: nil)
  end

  let(:mock) do
    double(denormalize: nil)
  end

  let(:wrapped) do
    klass.wrap(mock)
  end

  describe '#denormalize' do
    it 'raises if something other than hash is passed' do
      proc = lambda do
        denormalizer.denormalize(nil, type, context)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'uses factory to create entity' do
      expect(type.factory).to receive(:create).and_return(entity)
      expect(denormalizer.denormalize({}, type, context)).to eq(entity)
    end

    it 'sets attributes from provided hash' do
      data = { value: 12 }
      result = denormalizer.denormalize(data, type, context)
      expect(result.instance_variables).to include(:@value)
      expect(result.instance_variable_get(:@value)).to eq(data[:value])
    end

    it 'ignores virtual attributes' do
      data = { virtual: 12 }
      result = denormalizer.denormalize(data, type, context)
      expect(result.instance_variables).not_to include(:@virtual)
    end
  end

  describe '.wrap' do
    it 'returns output of wrapped denormalizer' do
      expect(mock).to receive(:denormalize).and_return(entity)
      expect(wrapped.denormalize({}, type, context)).to be(entity)
    end

    it 'provides fallback-block' do
      expect(mock).to receive(:denormalize) do |s, t, c, &block|
        block.call(s, t, c)
      end
      data = { value: 12 }
      result = wrapped.denormalize(data, type, context)
      expect(result.instance_variables).to include(:@value)
      expect(result.instance_variable_get(:@value)).to eq(data[:value])
    end

    it 'passes internal errors through' do
      error = mapping_error_class.new
      expect(mock).to receive(:denormalize).and_raise(error)
      proc = lambda do
        wrapped.denormalize({}, type, context)
      end
      expect(&proc).to raise_error(error)
    end

    it 'wraps unexpected errors' do
      expect(mock).to receive(:denormalize).and_raise(RuntimeError)
      proc = lambda do
        wrapped.denormalize({}, type, context)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'hints about invalid method signature' do
      expect(mock).to receive(:denormalize).and_raise(ArgumentError)
      proc = lambda do
        wrapped.denormalize({}, type, context)
      end
      regexp = /interface|contract|signature/i
      expect(&proc).to raise_error(compliance_error_class, regexp)
    end
  end
end
