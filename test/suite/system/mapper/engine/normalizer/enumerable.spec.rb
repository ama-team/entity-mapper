# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/engine/normalizer/enumerable'

klass = ::AMA::Entity::Mapper::Engine::Normalizer::Enumerable

describe klass do
  let(:normalizer) do
    klass.new
  end

  describe '#normalize' do
    it 'should normalize array as array' do
      expect(normalizer.normalize([1, 2])).to eq([1, 2])
    end

    it 'should normalize set as array' do
      expect(normalizer.normalize(Set.new([1]))).to eq([1])
    end
  end
end
