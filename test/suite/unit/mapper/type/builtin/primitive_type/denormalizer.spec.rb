# frozen_string_literal: true

require_relative '../../../../../../../lib/ama-entity-mapper/type/builtin/primitive_type/denormalizer'
require_relative '../../../../../../../lib/ama-entity-mapper/error/mapping_error'

klass = ::AMA::Entity::Mapper::Type::BuiltIn::PrimitiveType::Denormalizer
mapping_error_class = ::AMA::Entity::Mapper::Error::MappingError

describe klass do
  let(:type) do
    double(valid?: false)
  end

  let(:parent) do
    Class.new
  end

  let(:child) do
    Class.new(parent)
  end

  let(:grandchild) do
    Class.new(child)
  end

  let(:method_map) do
    {
      parent => %i[parent_a parent_b],
      child => %i[child_a child_b]
    }
  end

  let(:denormalizer) do
    klass.new(method_map)
  end

  let(:source) do
    double
  end

  describe '#denormalize' do
    it 'returns early if already of valid type' do
      expect(type).to receive(:valid?).and_return(true)
      expect(denormalizer.denormalize(source, type, ctx)).to equal(source)
    end

    it 'finds appropriate methods in method map if necessary' do
      method_map[parent].each do |method|
        allow(source).to receive(method).and_return(source)
        expect(source).not_to receive(method)
      end
      method_map[child].each do |method|
        allow(source).to receive(method).and_return(source)
        expect(source).to receive(method)
      end
      expect(type).to receive(:valid?).and_return(false, false, true)
      expect(source).to receive(:class).and_return(grandchild)
      expect(denormalizer.denormalize(source, type, ctx)).to eq(source)
    end

    it 'raises mapping error if every method has failed' do
      proc = lambda do
        denormalizer.denormalize(source, type, ctx)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end
  end
end
