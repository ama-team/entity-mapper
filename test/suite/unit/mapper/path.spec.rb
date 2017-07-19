# frozen_string_literal: true

require_relative '../../../../lib/mapper/path'

klass = ::AMA::Entity::Mapper::Path

describe klass do
  let(:default) do
    klass.new.index('0').attribute('attribute').property('property')
  end

  let(:empty) do
    klass.new
  end

  describe '#empty?' do
    it 'should return false on non-empty path' do
      expect(default.empty?).to be(false)
    end

    it 'should return true on empty path' do
      expect(empty.empty?).to be(true)
    end
  end

  describe '#each' do
    it 'should call provided block with every element' do
      result = []
      default.each do |item|
        result.push(item)
      end
      expect(result).to eq(default.to_a)
    end
  end

  describe '#reduce' do
    it 'should call provided block with every element' do
      result = default.reduce([]) do |carrier, item|
        carrier.push(item)
      end
      expect(result).to eq(default.to_a)
    end
  end

  describe '#pop' do
    it 'should create new path instance on pop' do
      path = default
      current = path.current
      copy = path.pop
      expect(path.current).to eq(current)
      expect(copy.to_a).to eq(path.to_a[0..-2])
    end
  end

  describe '#to_s' do
    it 'should be represented in standard pattern' do
      expect(default.to_s).to eq('$[0]#attribute.property')
    end
  end

  describe '#merge' do
    it 'should place merged segments in the end' do
      expectation = default.to_a.concat(default.to_a)
      expect(default.merge(default).to_a).to eq(expectation)
    end
  end

  describe '#push' do
    it 'should use attribute type by default' do
      path = empty.push(:default)
      compared_path = empty.attribute(:default)
      expect(path.size).to eq(1)
      expect(compared_path.size).to eq(1)
      expect(path.current).to eq(compared_path.current)
    end
  end
end
