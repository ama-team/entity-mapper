# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/api/default/denormalizer'
require_relative '../../../../../../lib/mapper/exception/mapping_error'

klass = ::AMA::Entity::Mapper::API::Default::Denormalizer
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError

describe klass do
  let(:denormalizer) do
    klass.new
  end

  let(:entity) do
    Class.new do
      attr_accessor :id
      attr_accessor :number
      attr_accessor :virtual
    end
  end

  let(:type) do
    attributes = {
      id: double(name: :id, virtual: false),
      number: double(name: :number, virtual: false),
      virtual: double(name: :virtual, virtual: true)
    }
    double(
      type: entity,
      factory: double(create: entity.new),
      attributes: attributes
    )
  end

  describe '#denormalize' do
    it 'raises error if anything but hash is passed in' do
      type = self.type
      proc = lambda do
        denormalizer.denormalize(double, type)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'denormalizes hash as standard attributes' do
      type = self.type
      values = { id: :josh, number: 12 }
      result = denormalizer.denormalize(values, type)
      expect(result).to be_a(entity)
      expect(result.id).to eq(values[:id])
      expect(result.number).to eq(values[:number])
    end

    it 'does not denormalize virtual attributes' do
      values = { virtual: 12 }
      result = denormalizer.denormalize(values, type)
      expect(result.virtual).to be_nil
    end
  end
end
