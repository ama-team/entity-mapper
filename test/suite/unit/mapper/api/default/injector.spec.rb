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
    double(name: :id, type: type)
  end

  describe '#inject' do
    it 'should inject attribute through accessor if it exists' do
      entity = double(:id= => nil)
      value = :symbol
      expect(entity).to receive(:id=).with(value).exactly(:once)
      injector.inject(entity, type, attribute, value)
    end

    it 'should inject attribute as variable if accessor is missing' do
      entity = double
      value = :symbol
      injector.inject(entity, type, attribute, value)
      expect(entity.instance_variable_get('@id')).to eq(value)
    end

    it 'should wrap error in mapping error' do
      entity = double(:id= => nil)
      value = :symbol
      expect(entity).to receive(:id=).and_raise
      proc = lambda do
        injector.inject(entity, type, attribute, value)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end
  end
end
