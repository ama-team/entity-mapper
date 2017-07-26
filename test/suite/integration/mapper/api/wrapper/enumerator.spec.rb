# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/api/wrapper/enumerator'
require_relative '../../../../../../lib/mapper/exception/mapping_error'

klass = ::AMA::Entity::Mapper::API::Wrapper::Enumerator
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError

describe klass do
  let(:id) do
    :j
  end

  let(:attribute) do
    double(name: :id, virtual: false, sensitive: false)
  end

  let(:type) do
    double(type: double, attributes: { id: attribute })
  end

  let(:entity) do
    Object.new.tap do |instance|
      instance.instance_variable_set('@id', id)
    end
  end

  describe '#enumerate' do
    it 'should provide fallback method' do
      enumerator = double
      expect(enumerator).to receive(:enumerate).exactly(:once) do |&block|
        block.call(entity, type)
      end
      proc = lambda do |block|
        klass.new(enumerator).enumerate(entity, type).each(&block)
      end
      expect(&proc).to yield_with_args([attribute, id, anything])
    end

    it 'should wrap exceptions in mapping error' do
      enumerator = double
      expect(enumerator).to receive(:enumerate).exactly(:once).and_raise
      proc = lambda do
        klass.new(enumerator).enumerate(entity, type)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'should provide informational message about method signature' do
      enumerator = double
      expect(enumerator).to(
        receive(:enumerate).exactly(:once).and_raise(ArgumentError)
      )
      proc = lambda do
        klass.new(enumerator).enumerate(entity, type)
      end
      regexp = /signature|interface|contract/i
      expect(&proc).to raise_error(mapping_error_class, regexp)
    end
  end
end
