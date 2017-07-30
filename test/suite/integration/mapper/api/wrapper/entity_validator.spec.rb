# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/api/wrapper/entity_validator'
require_relative '../../../../../../lib/mapper/exception/validation_error'
require_relative '../../../../../../lib/mapper/exception/compliance_error'

klass = ::AMA::Entity::Mapper::API::Wrapper::EntityValidator
compliance_error_class = ::AMA::Entity::Mapper::Exception::ComplianceError
validation_error_class = ::AMA::Entity::Mapper::Exception::ValidationError

describe klass do
  let(:context) do
    double(
      path: double(
        current: nil
      )
    )
  end

  let(:type) do
    double(
      instance?: true,
      enumerator: double(
        enumerate: Enumerator.new { |*| }
      )
    )
  end

  let(:value) do
    double
  end

  let(:factory) do
    lambda do
      klass.new(mock).validate(double, type, context)
    end
  end

  let(:mock) do
    double
  end

  describe '#validate' do
    it 'passes control to wrapped validator and provides fallback block' do
      expect(mock).to receive(:validate).exactly(:once) do |e, t, c, &block|
        block.call(e, t, c)
      end
      expect(factory.call).to eq([])
    end

    it 'passes through validator exceptions' do
      error = validation_error_class.new
      expect(mock).to receive(:validate).exactly(:once).and_raise(error)
      expect(&factory).to raise_error(error)
    end

    it 'wraps unexpected exceptions' do
      error = RuntimeError.new
      expect(mock).to receive(:validate).exactly(:once).and_raise(error)
      expect(&factory).to raise_error(compliance_error_class)
    end

    it 'hints about invalid method signature' do
      error = ArgumentError.new
      expect(mock).to receive(:validate).exactly(:once).and_raise(error)
      regexp = /signature|interface|contract/i
      expect(&factory).to raise_error(compliance_error_class, regexp)
    end

    it 'catches invalid return type' do |test_case|
      variants = [
        nil,
        [1],
        [[]],
        [[double(is_a?: true), double(is_a?: true), double(is_a?: false)]]
      ]

      variants.each do |variant|
        test_case.step "feeding in #{variant}" do
          expect(mock).to receive(:validate).and_return(variant)
          expect(&factory).to raise_error(compliance_error_class)
        end
      end
    end
  end
end
