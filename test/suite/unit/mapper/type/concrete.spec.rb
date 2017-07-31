# frozen_string_literal: true

require_relative '../../../../../lib/mapper/type/concrete'
require_relative '../../../../../lib/mapper/error/compliance_error'

klass = ::AMA::Entity::Mapper::Type::Concrete
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError

describe klass do
  let(:dummy) do
    Class.new
  end

  let(:attribute) do
    double
  end

  let(:parameter) do
    double
  end

  let(:left) do
    klass.new(dummy).tap do |type|
      type.attributes[:T] = attribute
      type.parameters[:T] = parameter
    end
  end

  let(:right) do
    klass.new(dummy).tap do |type|
      type.attributes[:T] = attribute
      type.parameters[:T] = parameter
    end
  end

  let(:different) do
    klass.new(dummy)
  end

  let(:completely_different) do
    klass.new(Class.new)
  end

  describe '#initialize' do
    it 'should raise error if invalid input was provided' do
      proc = lambda do
        klass.new(12)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end
  end

  describe '#eql?' do
    it 'should be equal to another type for same class with same attributes' do
      expect(left).to eq(right)
    end

    it 'returns false if attributes differ' do
      expect(left).not_to eq(different)
    end

    it 'returns false if enclosed classes differ' do
      expect(different).not_to eq(completely_different)
    end
  end

  describe '#hash' do
    it 'should be equal among types for same class with same attributes' do
      expect(left.hash).to eq(right.hash)
    end
  end

  describe '#instance?' do
    it 'should return true if provided argument is_a enclosed class' do
      expect(klass.new(dummy).instance?(dummy.new)).to be true
    end

    it 'should return false if provided argument is not an instance of class' do
      expect(klass.new(Class.new).instance?(Class.new)).to be false
    end
  end
end
