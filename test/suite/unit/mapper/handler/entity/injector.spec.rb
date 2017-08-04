# frozen_string_literal: true

# rubocop:disable Metrics/ParameterLists

require_relative '../../../../../../lib/mapper/handler/entity/injector'
require_relative '../../../../../../lib/mapper/error/compliance_error'

klass = ::AMA::Entity::Mapper::Handler::Entity::Injector
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError

describe klass do
  let(:injector) do
    klass::INSTANCE
  end

  let(:attribute) do
    double(
      name: :value,
      virtual: false
    )
  end

  let(:virtual_attribute) do
    double(
      name: :virtual,
      virtual: true
    )
  end

  let(:type) do
    double
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
    double(inject: nil)
  end

  let(:wrapped) do
    klass.wrap(mock)
  end

  describe '#inject' do
    it 'injects attribute via setter, if present' do
      value = double
      entity = double(:value=)
      expect(entity).to receive(:value=).with(value)
      injector.inject(entity, type, attribute, value, context)
    end

    it 'injects attribute via instance variable if setter is missing' do
      value = double
      injector.inject(entity, type, attribute, value, context)
      expect(entity.instance_variables).to include(:@value)
      expect(entity.instance_variable_get(:@value)).to eq(value)
    end

    it 'skips virtual attributes' do
      value = double
      entity = double(:virtual=)
      expect(entity).not_to receive(:virtual=)
      injector.inject(entity, type, virtual_attribute, value, context)
    end
  end

  describe '.wrap' do
    it 'returns invokes wrapped implementation' do
      value = double
      expect(mock).to(
        receive(:inject).with(entity, type, attribute, value, context)
      )
      wrapped.inject(entity, type, attribute, value, context)
    end

    it 'provides fallback-block' do
      value = double
      expect(entity).to receive(:value=).with(value)
      expect(mock).to receive(:inject) do |e, t, a, d, c, &block|
        block.call(e, t, a, d, c)
      end
      wrapped.inject(entity, type, attribute, value, context)
    end

    it 'passes internal exceptions through' do
      error = compliance_error_class.new
      expect(mock).to receive(:inject).and_raise(error)
      proc = lambda do
        wrapped.inject(entity, type, attribute, double, context)
      end
      expect(&proc).to raise_error(error)
    end

    it 'wraps unexpected errors' do
      expect(mock).to receive(:inject).and_raise(RuntimeError)
      proc = lambda do
        wrapped.inject(entity, type, attribute, double, context)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'hints about invalid method signature' do
      expect(mock).to receive(:inject).and_raise(ArgumentError)
      proc = lambda do
        wrapped.inject(entity, type, attribute, double, context)
      end
      regexp = /interface|contract|signature/i
      expect(&proc).to raise_error(compliance_error_class, regexp)
    end
  end
end
