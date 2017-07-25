# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/api/wrapper/injector'
require_relative '../../../../../../lib/mapper/exception/mapping_error'

klass = ::AMA::Entity::Mapper::API::Wrapper::Injector
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError

describe klass do
  let(:id) do
    :tilt
  end

  let(:attribute) do
    double(name: :id)
  end

  let(:type) do
    double(type: double)
  end

  let(:entity) do
    double
  end

  describe '#inject' do
    it 'should provide fallback method' do
      injector = double
      expect(injector).to receive(:inject).exactly(:once) do |&block|
        block.call(entity, type, attribute, id)
      end
      klass.new(injector).inject(entity, type, attribute, id)
      expect(entity.instance_variable_get('@id')).to eq(id)
    end

    it 'should wrap exceptions in mapping error' do
      injector = double
      expect(injector).to receive(:inject).exactly(:once).and_raise
      proc = lambda do
        klass.new(injector).inject(entity, type, attribute, id)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'should provide informational message about method signature' do
      injector = double
      expect(injector).to(
        receive(:inject).exactly(:once).and_raise(ArgumentError)
      )
      proc = lambda do
        klass.new(injector).inject(entity, type, attribute, id)
      end
      regexp = /signature|interface|contract/i
      expect(&proc).to raise_error(mapping_error_class, regexp)
    end
  end
end
