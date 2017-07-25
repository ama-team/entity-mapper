# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/api/wrapper/factory'
require_relative '../../../../../../lib/mapper/exception/mapping_error'

klass = ::AMA::Entity::Mapper::API::Wrapper::Factory
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError

describe klass do
  let(:type) do
    double(type: double)
  end

  describe '#create' do
    it 'should provide fallback to default factory' do
      result = double
      expect(type.type).to receive(:new).exactly(:once).and_return(result)
      factory = double
      expect(factory).to receive(:create).exactly(:once) do |&block|
        block.call(type)
      end
      expect(klass.new(factory).create(type)).to eq(result)
    end

    it 'should wrap exceptions in mapping error' do
      factory = double
      expect(factory).to receive(:create).exactly(:once).and_raise
      proc = lambda do
        klass.new(factory).create(type)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'should provide hint about method signature' do
      factory_class = Class.new do
        def create; end
      end
      factory = factory_class.new
      proc = lambda do
        klass.new(factory).create(type)
      end
      regexp = /signature|interface|contract/i
      expect(&proc).to raise_error(mapping_error_class, regexp)
    end
  end
end
