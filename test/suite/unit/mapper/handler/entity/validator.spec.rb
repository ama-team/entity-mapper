# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/handler/entity/validator'

klass = ::AMA::Entity::Mapper::Handler::Entity::Validator
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError

describe klass do
  let(:validator) do
    klass::INSTANCE
  end

  let(:type) do
    double(
      type: nil,
      instance?: true
    )
  end

  let(:context) do
    double(
      path: nil,
      advance: nil
    )
  end

  let(:mock) do
    double(validate: [])
  end

  let(:wrapped) do
    klass.wrap(mock)
  end

  describe '#validate' do
    it 'returns no violations if #instance? check passes' do
      expect(validator.validate(double, type, context)).to eq([])
    end

    it 'reports if #instance? check fails' do
      expect(type).to receive(:instance?).and_return(false)
      expect(validator.validate(double, type, context)).to_not be_empty
    end
  end

  describe '.wrap' do
    it 'returns output from wrapped validator' do
      expect(wrapped.validate(double, type, context)).to eq([])
    end

    it 'provides fallback-block' do
      expect(type).to receive(:instance?).and_return(false)
      expect(mock).to receive(:validate) do |e, t, c, &block|
        block.call(e, t, c)
      end
      expect(wrapped.validate(double, type, context)).not_to be_empty
    end

    it 'passes through internal errors' do
      error = compliance_error_class.new
      expect(mock).to receive(:validate).and_raise(error)
      proc = lambda do
        wrapped.validate(double, type, context)
      end
      expect(&proc).to raise_error(error)
    end

    it 'wraps unexpected errors' do
      expect(mock).to receive(:validate).and_raise(RuntimeError)
      proc = lambda do
        wrapped.validate(double, type, context)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'provides hint about invalid method signature' do
      expect(mock).to receive(:validate).and_raise(ArgumentError)
      proc = lambda do
        wrapped.validate(double, type, context)
      end
      regexp = /interface|contract|signature/i
      expect(&proc).to raise_error(compliance_error_class, regexp)
    end
  end
end
