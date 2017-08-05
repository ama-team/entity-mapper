# frozen_string_literal: true

require_relative '../../../../../../lib/ama-entity-mapper/handler/entity/factory'
require_relative '../../../../../../lib/ama-entity-mapper/error/compliance_error'
require_relative '../../../../../../lib/ama-entity-mapper/error/mapping_error'

klass = ::AMA::Entity::Mapper::Handler::Entity::Factory
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError
mapping_error_class = ::AMA::Entity::Mapper::Error::MappingError

describe klass do
  let(:factory) do
    klass::INSTANCE
  end

  let(:attributes) do
    {
      value: double(
        name: :value,
        default: nil,
        virtual: false
      ),
      default: double(
        name: :default,
        default: {},
        virtual: false
      ),
      virtual: double(
        name: :virtual,
        default: {},
        virtual: true
      )
    }
  end

  let(:entity) do
    double
  end

  let(:type) do
    double(
      type: double(new: entity),
      attributes: attributes,
      injector: double(inject: nil)
    )
  end

  let(:context) do
    double(
      path: nil,
      advance: nil
    )
  end

  let(:mock) do
    double(create: entity)
  end

  let(:wrapped) do
    klass.wrap(mock)
  end

  describe '#create' do
    it 'creates entity using class #new method' do
      expect(type.type).to receive(:new).exactly(:once).and_return(entity)
      expect(factory.create(type, double, context)).to be(entity)
    end

    it 'sets non-virtual attributes with default values' do
      attribute = attributes[:default]
      value = attribute.default
      expect(type.injector).to(
        receive(:inject).with(entity, type, attribute, value, anything)
      )
      %i[virtual value].each do |name|
        attribute = attributes[name]
        value = attribute.default
        expect(type.injector).not_to(
          receive(:inject).with(entity, type, attribute, value, anything)
        )
      end
      factory.create(type, double, context)
    end

    it 'gives a hint about existing parameters in constructor' do
      expect(type.type).to receive(:new).exactly(:once).and_raise(ArgumentError)
      proc = lambda do
        factory.create(type, double, context)
      end
      regexp = /initialize/i
      expect(&proc).to raise_error(mapping_error_class, regexp)
    end
  end

  describe '.wrap' do
    it 'returns wrapped implementation response' do
      value = double
      expect(mock).to receive(:create).and_return(value)
      expect(wrapped.create(type, double, context)).to be(value)
    end

    it 'provides fallback-block' do
      value = double
      expect(mock).to receive(:create) do |t, d, c, &block|
        block.call(t, d, c)
      end
      expect(type.type).to receive(:new).and_return(value)
      expect(wrapped.create(type, double, context)).to be(value)
    end

    it 'passes internal exceptions through' do
      error = compliance_error_class.new
      expect(mock).to receive(:create).and_raise(error)
      proc = lambda do
        wrapped.create(type, double, context)
      end
      expect(&proc).to raise_error(error)
    end

    it 'wraps unexpected errors' do
      expect(mock).to receive(:create).and_raise(RuntimeError)
      proc = lambda do
        wrapped.create(type, double, context)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'hints about invalid method signature' do
      expect(mock).to receive(:create).and_raise(ArgumentError)
      proc = lambda do
        wrapped.create(type, double, context)
      end
      regexp = /interface|contract|signature/i
      expect(&proc).to raise_error(compliance_error_class, regexp)
    end
  end
end
