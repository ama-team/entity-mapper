# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/api/default/factory'
require_relative '../../../../../../lib/mapper/exception/mapping_error'

klass = ::AMA::Entity::Mapper::API::Default::Factory
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError

describe klass do
  let(:factory) do
    klass.new
  end

  describe '#create' do
    it 'should instantiate class by issuing direct #new() call' do
      value = double
      type = double(type: double)
      expect(type.type).to receive(:new).and_return(value)
      expect(factory.create(type)).to eq(value)
    end

    it 'should raise mapping error in case of faulty constructor' do
      type = double(type: double)
      expect(type.type).to receive(:new).and_raise
      proc = lambda do
        factory.create(type)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'should include information about invalid method signature in case of argument error' do
      type = double(type: double)
      expect(type.type).to receive(:new).and_raise(ArgumentError)
      proc = lambda do
        factory.create(type)
      end
      expect(&proc).to raise_error(mapping_error_class, /initialize|constructor/)
    end
  end
end
