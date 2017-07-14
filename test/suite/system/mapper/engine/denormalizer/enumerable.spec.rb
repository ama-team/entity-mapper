# frozen_string_literal: true

require 'set'

require_relative '../../../../../../lib/mapper/engine/denormalizer/enumerable'
require_relative '../../../../../../lib/mapper/exception/mapping_error'

klass = ::AMA::Entity::Mapper::Engine::Denormalizer::Enumerable

describe klass do
  let(:denormalizer) do
    klass.new
  end

  let(:context) do
    nil
  end

  describe '#denormalize' do
    it 'should denormalize set with ease' do
      type = double(type: Set)
      result = denormalizer.denormalize([1, 2], context, type)
      expect(result).to eq(Set.new([1, 2]))
    end

    it 'should raise if type can\'t be instantiated' do
      type = double(type: Class.new { include Enumerable })
      expectation = expect do
        denormalizer.denormalize([1, 2], context, type)
      end
      expectation.to raise_error(::AMA::Entity::Mapper::Exception::MappingError)
    end
  end
end
