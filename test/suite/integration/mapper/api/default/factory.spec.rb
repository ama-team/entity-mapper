# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/api/default/factory'
require_relative '../../../../../../lib/mapper/exception/mapping_error'

klass = ::AMA::Entity::Mapper::API::Default::Factory
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError

describe klass do
  let(:factory) do
    klass.new
  end

  let(:context) do
    double(
      path: double
    )
  end

  let(:type) do
    double(
      type: double,
      attributes: {
        counter: double(
          name: :counter,
          default: 0,
          virtual: false
        ),
        value: double(
          name: :value,
          default: nil,
          virtual: false
        ),
        _element: double(
          name: :_element,
          default: {},
          virtual: true
        )
      },
      injector: double(inject: nil)
    )
  end

  describe '#create' do
    it 'instantiates class by issuing direct #new() call' do
      value = double
      allow(type).to receive(:attributes).and_return({})
      expect(type.type).to receive(:new).and_return(value)
      expect(factory.create(type, double, context)).to eq(value)
    end

    it 'wraps constructor errors' do
      expect(type.type).to receive(:new).and_raise
      proc = lambda do
        factory.create(type, double, context)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'reports invalid method signature in case of argument error' do
      expect(type.type).to receive(:new).and_raise(ArgumentError)
      proc = lambda do
        factory.create(type, double, context)
      end
      expect(&proc).to raise_error(mapping_error_class, /initialize|constructor/)
    end

    it 'fills entity with default attribute values' do
      dummy = double
      expect(type.type).to receive(:new).and_return(dummy)

      attribute = type.attributes[:counter]
      match = receive(:inject).with(dummy, type, attribute, 0, anything)
      expect(type.injector).to(match)

      attribute = type.attributes[:value]
      match = receive(:inject).with(dummy, type, attribute, anything, anything)
      expect(type.injector).not_to(match)

      factory.create(type, double, context)
    end

    it 'ignores virtual attributes' do
      dummy = double
      expect(type.type).to receive(:new).and_return(dummy)

      attribute = type.attributes[:_element]
      match = receive(:inject).with(dummy, type, attribute, anything, anything)
      expect(type.injector).not_to(match)

      factory.create(type, double, context)
    end
  end
end
