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
    end
  end

  describe '#denormalize' do
    it 'should raise error if anything but hash is passed in' do
      proc = lambda do
        denormalizer.denormalize(Object.new, double, double(type: Class.new))
      end
      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'should denormalize hash as standard attributes' do
      values = { id: :josh, number: 12 }
      type = double(type: entity)
      result = denormalizer.denormalize(entity.new, values, type)
      expect(result).to be_a(entity)
      expect(result.id).to eq(values[:id])
      expect(result.number).to eq(values[:number])
    end
  end
end
