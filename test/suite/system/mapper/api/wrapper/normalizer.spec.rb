# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/api/wrapper/normalizer'
require_relative '../../../../../../lib/mapper/exception/mapping_error'

klass = ::AMA::Entity::Mapper::API::Wrapper::Normalizer
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError

describe klass do
  let(:id) do
    :jenkins
  end

  let(:attribute) do
    double(name: :id)
  end

  let(:type) do
    double(type: double)
  end

  let(:entity) do
    Object.new.tap do |object|
      object.instance_variable_set('@id', id)
    end
  end

  let(:normalizer) do
    double
  end

  describe '#normalize' do
    it 'should provide fallback method' do
      expect(normalizer).to receive(:normalize).exactly(:once) do |&block|
        block.call(entity, type)
      end
      result = klass.new(normalizer).normalize(entity, type)
      expect(result).to eq(id: id)
    end

    it 'should wrap exceptions in mapping error' do
      expect(normalizer).to receive(:normalize).exactly(:once).and_raise
      proc = lambda do
        klass.new(normalizer).normalize(entity, type)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'should provide informational message about method signature' do
      expect(normalizer).to(
        receive(:normalize).exactly(:once).and_raise(ArgumentError)
      )
      proc = lambda do
        klass.new(normalizer).normalize(entity, type)
      end
      regexp = /signature|interface|contract/i
      expect(&proc).to raise_error(mapping_error_class, regexp)
    end
  end
end
