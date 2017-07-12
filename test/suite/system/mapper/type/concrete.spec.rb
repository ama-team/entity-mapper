# frozen_string_literal: true

require_relative '../../../../../lib/mapper/type/concrete'

klass = ::AMA::Entity::Mapper::Type::Concrete

describe klass do
  let(:parameterized) do
    klass.new(Class.new).tap do |instance|
      instance.attribute(:id, Symbol)
      instance.attribute(:value, :T)
    end
  end

  let(:resolved) do
    klass.new(Class.new).tap do |instance|
      instance.attribute(:id, Symbol)
    end
  end

  let(:unresolved_attribute) do
    klass.new(Class.new).tap do |instance|
      instance.attribute(:id, Symbol)
      instance.attribute(:value, parameterized)
    end
  end

  let(:nested) do
    klass.new(Class.new).tap do |instance|
      instance.attribute(:id, Symbol)
      attribute = instance.attribute(:value, parameterized)
      attribute.types.first.attributes[:value].types[0] = instance.parameter(:T)
      attribute.types.first.parameters[:T] = instance.parameter(:T)
    end
  end

  let(:identical_type_pair) do
    described_klass = Class.new
    Array.new(2) do
      klass.new(described_klass).tap do |type|
        type.attribute(:id, Symbol)
        type.attribute(:value, :T)
      end
    end
  end

  describe '#resolved?' do
    it 'should return false if there is at least one unresolved parameter' do
      expect(parameterized.resolved?).to be false
    end

    it 'should return false if there is at least one unresolved attribute' do
      expect(unresolved_attribute.resolved?).to be false
    end

    it 'should return true once all parameters are resolved' do
      type = parameterized
      subject = type.parameters[:T]
      replacement = klass.new(Class.new)
      type.resolve(subject => replacement)
      expect(type.resolved?).to be true
    end
  end

  describe '#resolve' do
    it 'should resolve simple case' do
      type = parameterized
      expect(type.resolved?).to be false
      type.resolve(type.variable(:T) => resolved)
      expect(type.resolved?).to be true
    end

    it 'should recursively resolve types' do
      type = nested
      expect(type.resolved?).to be false
      type.resolve(type.variable(:T) => resolved)
      expect(type.resolved?).to be true
    end
  end

  describe '#hash' do
    it 'should be equal for types with same class, parameters and attributes' do
      types = identical_type_pair
      expect(types.first.hash).to eq(types.last.hash)
    end
  end

  describe '#eql?' do
    it 'should return true for types of same class' do |test_case|
      types = identical_type_pair
      test_case.step 'full equality' do
        expect(types.first).to eq(types.last)
      end
      test_case.step 'introducing new variable' do
        types.first.variable(:E)
        expect(types.first).to eq(types.last)
      end
      test_case.step 'introducing new attribute' do
        types.first.attribute(:bingo, TrueClass, FalseClass)
        expect(types.first).to eq(types.last)
      end
    end
  end

  describe '#clone' do
    it 'should return instance equal to cloned' do
      expect(parameterized.clone).to eq(parameterized)
    end
  end
end
