# frozen_string_literal: true

require_relative '../../../../../lib/mapper/type/concrete'
require_relative '../../../../../lib/mapper/exception/compliance_error'

klass = ::AMA::Entity::Mapper::Type::Concrete
compliance_error_class = ::AMA::Entity::Mapper::Exception::ComplianceError

describe klass do
  let(:dummy) do
    Class.new
  end

  let(:left) do
    klass.new(dummy)
  end

  let(:right) do
    klass.new(dummy).tap do |type|
      type.attributes[:T] = double
      type.parameters[:T] = double
    end
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
    it 'should be equal to another type for same class' do
      expect(left).to eq(right)
    end
  end

  describe '#hash' do
    it 'should be equal among types for same class' do
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
