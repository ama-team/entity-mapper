# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/handler/entity/normalizer'
require_relative '../../../../../../lib/mapper/error/compliance_error'

klass = ::AMA::Entity::Mapper::Handler::Entity::Normalizer
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError

describe klass do
  let(:normalizer) do
    klass::INSTANCE
  end

  let(:attributes) do
    {
      value: double(
        name: :value,
        sensitive: false,
        virtual: false
      ),
      sensitive: double(
        name: :sensitive,
        sensitive: true,
        virtual: false
      ),
      virtual: double(
        name: :virtual,
        sensitive: false,
        virtual: true
      )
    }
  end

  let(:type) do
    double(
      attributes: attributes
    )
  end

  let(:context) do
    double(
      path: nil,
      advance: nil
    )
  end

  let(:entity) do
    double
  end

  let(:mock) do
    double(normalize: {})
  end

  let(:wrapped) do
    klass.wrap(mock)
  end

  describe '#normalize' do
    it 'emits values for existing attributes' do
      value = double
      entity.instance_variable_set(:@value, value)
      result = normalizer.normalize(entity, type, context)
      expect(result).to be_a(Hash)
      expect(result).to include(:value)
      expect(result[:value]).to eq(value)
    end

    it 'doesn\'t skip attributes without a value' do
      result = normalizer.normalize(entity, type, context)
      expect(result).to be_a(Hash)
      expect(result).to include(:value)
      expect(result[:value]).to be_nil
    end

    it 'skips sensitive attributes' do
      result = normalizer.normalize(entity, type, context)
      expect(result).to be_a(Hash)
      expect(result).not_to include(:sensitive)
    end

    it 'skips virtual attributes' do
      result = normalizer.normalize(entity, type, context)
      expect(result).to be_a(Hash)
      expect(result).not_to include(:virtual)
    end
  end

  describe '.wrap' do
    it 'returns wrapped implementation response' do
      value = double
      expect(mock).to receive(:normalize).and_return(value)
      expect(wrapped.normalize(entity, type, context)).to be(value)
    end

    it 'provides fallback-block' do
      value = double
      entity.instance_variable_set(:@value, value)
      expect(mock).to receive(:normalize) do |e, t, c, &block|
        block.call(e, t, c)
      end
      result = wrapped.normalize(entity, type, context)
      expect(result).to be_a(Hash)
      expect(result).to include(:value)
      expect(result[:value]).to eq(value)
    end

    it 'passes internal exceptions through' do
      error = compliance_error_class.new
      expect(mock).to receive(:normalize).and_raise(error)
      proc = lambda do
        wrapped.normalize(entity, type, context)
      end
      expect(&proc).to raise_error(error)
    end

    it 'wraps unexpected errors' do
      expect(mock).to receive(:normalize).and_raise(RuntimeError)
      proc = lambda do
        wrapped.normalize(entity, type, context)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'hints about invalid method signature' do
      expect(mock).to receive(:normalize).and_raise(ArgumentError)
      proc = lambda do
        wrapped.normalize(entity, type, context)
      end
      regexp = /interface|contract|signature/i
      expect(&proc).to raise_error(compliance_error_class, regexp)
    end
  end
end
