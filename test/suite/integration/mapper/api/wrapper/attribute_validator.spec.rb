# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/api/wrapper/attribute_validator'
require_relative '../../../../../../lib/mapper/exception/validation_error'
require_relative '../../../../../../lib/mapper/exception/compliance_error'

klass = ::AMA::Entity::Mapper::API::Wrapper::AttributeValidator
compliance_error_class = ::AMA::Entity::Mapper::Exception::ComplianceError
validation_error_class = ::AMA::Entity::Mapper::Exception::ValidationError

describe klass do
  let(:value) do
    double
  end

  let(:attribute) do
    double(
      default: nil,
      values: [],
      nullable: true,
      types: [double(instance?: true)]
    )
  end

  let(:context) do
    double(path: nil)
  end

  let(:mock) do
    double
  end

  let(:factory) do
    lambda do
      klass.new(mock).validate(value, attribute, context)
    end
  end

  describe '#validate' do
    it 'passes control to wrapped validator and provides fallback block' do
      expect(mock).to receive(:validate).exactly(:once) do |v, a, c, &block|
        block.call(v, a, c)
      end
      expect(factory.call).to eq([])
    end

    it 'wraps single string violation with array' do
      violation = 'violation'
      expect(mock).to receive(:validate).exactly(:once).and_return(violation)
      expect(factory.call).to eq([violation])
    end

    it 'converts nil response into array' do
      expect(mock).to receive(:validate).exactly(:once).and_return(nil)
      expect(factory.call).to eq([])
    end

    it 'passes through validator exceptions' do
      error = validation_error_class.new
      expect(mock).to receive(:validate).and_raise(error)
      expect(&factory).to raise_error(error)
    end

    it 'wraps unexpected exceptions' do
      error = RuntimeError.new
      expect(mock).to receive(:validate).and_raise(error)
      expect(&factory).to raise_error(compliance_error_class)
    end

    it 'hints about invalid method signature' do
      error = ArgumentError.new
      expect(mock).to receive(:validate).and_raise(error)
      regexp = /signature|interface|contract/i
      expect(&factory).to raise_error(compliance_error_class, regexp)
    end
  end
end
