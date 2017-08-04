# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/handler/attribute/validator'
require_relative '../../../../../../lib/mapper/error/compliance_error'

klass = ::AMA::Entity::Mapper::Handler::Attribute::Validator
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError

describe klass do
  let(:validator) do
    klass::INSTANCE
  end

  let(:mock) do
    double(validate: [])
  end

  let(:wrapped) do
    klass.wrap(mock)
  end

  let(:type) do
    double(instance?: true, to_def: '(Virtual Type)')
  end

  let(:attribute) do
    double(
      nullable: false,
      types: [type],
      values: [],
      default: nil,
      to_def: '(Virtual Attribute)'
    )
  end

  let(:context) do
    double(path: nil)
  end

  describe '#validate' do
    it 'accepts nil for nullable attribute' do
      allow(attribute).to receive(:nullable).and_return(true)
      expect(validator.validate(nil, attribute, context)).to eq([])
    end

    it 'accepts nil for attribute with NilClass type' do
      expect(validator.validate(nil, attribute, context)).to eq([])
    end

    it 'reports violation for nil value of non-nullable attribute' do
      allow(attribute.types.first).to receive(:instance?).and_return(false)
      expect(validator.validate(nil, attribute, context)).not_to be_empty
    end

    it 'reports violation for value not satisfied by any of types' do
      allow(attribute.types.first).to receive(:instance?).and_return(false)
      expect(validator.validate(double, attribute, context)).not_to be_empty
    end

    it 'accepts value equal to default' do
      value = double
      allow(attribute).to receive(:default).and_return(value)
      expect(validator.validate(value, attribute, context)).to eq([])
    end

    it 'accepts value in allowed values list' do
      value = double
      allow(attribute).to receive(:values).and_return([value])
      expect(validator.validate(value, attribute, context)).to eq([])
    end

    it 'reports violation for value not equal to default / not in allowed values list' do
      allow(attribute).to receive(:values).and_return([double])
      expect(validator.validate(double, attribute, context)).not_to be_empty
    end
  end

  describe '.wrap' do
    it 'returns user-provided validator output' do
      expect(wrapped.validate(double, attribute, context)).to eq([])
    end

    it 'provides fallback-block' do
      allow(attribute.types.first).to receive(:instance?).and_return(false)
      allow(mock).to receive(:validate) do |v, a, c, &block|
        block.call(v, a, c)
      end
      expect(wrapped.validate(double, attribute, context)).not_to be_empty
    end

    it 'passes through internal exceptions' do
      error = compliance_error_class.new
      allow(mock).to receive(:validate).and_raise(error)
      proc = lambda do
        wrapped.validate(double, attribute, context)
      end
      expect(&proc).to raise_error(error)
    end

    it 'wraps unexpected exceptions' do
      allow(mock).to receive(:validate).and_raise
      proc = lambda do
        wrapped.validate(double, attribute, context)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'hints about invalid signature' do
      allow(mock).to receive(:validate).and_raise(ArgumentError)
      proc = lambda do
        wrapped.validate(double, attribute, context)
      end
      regexp = /interface|contract|signature/i
      expect(&proc).to raise_error(compliance_error_class, regexp)
    end
  end
end
