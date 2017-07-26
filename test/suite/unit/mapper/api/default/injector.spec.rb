# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/api/default/injector'
require_relative '../../../../../../lib/mapper/exception/mapping_error'

klass = ::AMA::Entity::Mapper::API::Default::Injector
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError

describe klass do
  let(:injector) do
    klass.new
  end

  let(:type) do
    double(type: double)
  end

  let(:attribute) do
    double(name: :id, type: type, virtual: false)
  end

  let(:virtual_attribute) do
    double(name: :virtual, type: type, virtual: true)
  end

  describe '#inject' do
    it 'injects attribute using setter if it exists' do
      entity = double(:id= => nil)
      value = :symbol
      expect(entity).to receive(:id=).with(value).exactly(:once)
      injector.inject(entity, type, attribute, value)
    end

    it 'injects attribute as variable if s is missing' do
      entity = double
      value = :symbol
      injector.inject(entity, type, attribute, value)
      expect(entity.instance_variable_get('@id')).to eq(value)
    end

    it 'wraps errors in mapping error' do
      entity = double(:id= => nil)
      expect(entity).to receive(:id=).and_raise
      proc = lambda do
        injector.inject(entity, type, attribute, :symbol)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'ignores virtual attributes' do
      entity = double(:id= => nil)
      attribute = virtual_attribute
      expect(entity).not_to receive(:id=)
      injector.inject(entity, type, attribute, :symbol)
    end
  end
end
