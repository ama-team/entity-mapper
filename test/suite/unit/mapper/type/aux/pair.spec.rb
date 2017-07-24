# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/type/aux/pair'

klass = ::AMA::Entity::Mapper::Type::Aux::Pair

describe klass do
  describe '#eql?' do
    it 'should return true for pairs with same content' do
      data = { left: 1, right: 2 }
      expect(klass.new(data)).to eq(klass.new(data))
    end

    it 'should return false for pairs with different content' do
      data = { left: 1, right: 2 }
      expect(klass.new(data)).not_to eq(klass.new(data.merge(right: 3)))
    end
  end

  describe '#hash' do
    it 'should return same values for pairs with same content' do
      data = { left: 1, right: 2 }
      expect(klass.new(data).hash).to eq(klass.new(data).hash)
    end
  end
end
