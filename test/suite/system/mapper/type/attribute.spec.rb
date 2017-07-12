# frozen_string_literal: true

require_relative '../../../../../lib/mapper/type/attribute'
require_relative '../../../../../lib/mapper/type/concrete'

klass = ::AMA::Entity::Mapper::Type::Attribute
type_klass = ::AMA::Entity::Mapper::Type::Concrete

describe klass do
  describe '#eql?' do
    it 'should return true if owners and names match' do
      type = type_klass.new(Class.new)
      instances = Array.new(2) do
        klass.new(type, :id, type)
      end
      expect(instances.first).to eq(instances.last)
    end

    it 'should return false if owners differ' do
      type = type_klass.new(Class.new)
      instances = Array.new(2) do |index|
        klass.new(type_klass.new(Class.new), index.to_s.to_sym, type)
      end
      expect(instances.first).not_to eq(instances.last)
    end

    it 'should return false if names differ' do
      type = type_klass.new(Class.new)
      instances = Array.new(2) do |index|
        klass.new(type, index.to_s.to_sym, type)
      end
      expect(instances.first).not_to eq(instances.last)
    end
  end

  describe '#hash' do
    it 'should return equal values for identical instances' do
      type = type_klass.new(Class.new)
      instances = Array.new(2) do
        klass.new(type, :id, type)
      end
      expect(instances.first.hash).to eq(instances.last.hash)
    end
  end
end
