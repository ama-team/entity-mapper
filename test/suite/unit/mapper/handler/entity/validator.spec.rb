# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/handler/entity/validator'

klass = ::AMA::Entity::Mapper::Handler::Entity::Validator
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError

describe klass do
  let(:validator) do
    klass::INSTANCE
  end

  let(:attributes) do
    {
      id: double(
        name: :id,
        virtual: false,
        validator: double(validate: [])
      ),
      virtual: double(
        name: :virtual,
        virtual: true,
        validator: double(validate: ['violation'])
      )
    }
  end

  let(:type) do
    double(
      type: double,
      attributes: attributes,
      enumerator: double(
        enumerate: ::Enumerator.new do |y|
          attributes.values.each do |a|
            y << [a, nil, double]
          end
        end
      )
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
    it 'passes all the work onto attribute validators' do
      expect(attributes[:id].validator).to receive(:validate).and_return([])
      expect(validator.validate(double, type, context)).to eq([])
    end

    it 'omits virtual attributes' do
      expect(attributes[:virtual].validator).not_to receive(:validate)
      expect(validator.validate(double, type, context)).to eq([])
    end
  end

  describe '.wrap' do
    it 'returns output from wrapped validator' do
      expect(wrapped.validate(double, type, context)).to eq([])
    end

    it 'provides fallback-block' do
      violation = 'violation'
      expect(attributes[:id].validator).to(
        receive(:validate).and_return([violation])
      )
      expect(mock).to receive(:validate) do |e, t, c, &block|
        block.call(e, t, c)
      end
      expectation = [attributes[:id], violation]
      result = wrapped.validate(double, type, context)
      expect(result).not_to be_empty
      expect(result.first[0..1]).to eq(expectation)
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
