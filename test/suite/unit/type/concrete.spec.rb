# frozen_string_literal: true

require_relative '../../../../lib/mapper/type/concrete'
require_relative '../../../../lib/mapper/exception/mapping_error'
require_relative '../../../../lib/mapper/exception/compliance_error'

klass = ::AMA::Entity::Mapper::Type::Concrete
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError
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

  describe '#instantiate' do
    it 'should wrap error from custom factory' do
      type = klass.new(Class.new).tap do |instance|
        instance.factory = lambda do |*|
          raise 'woot'
        end
      end

      proc = lambda do
        type.instantiate
      end

      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'should provide informational error if user passed class with parameterful #initialize()' do
      dummy = Class.new do
        def initialize(_) end
      end

      proc = lambda do
        klass.new(dummy).instantiate
      end

      expect(&proc).to raise_error(mapping_error_class, /initialize/)
    end

    it 'should wrap #initialize() error' do
      dummy = Class.new do
        def initialize(_)
          raise
        end
      end

      proc = lambda do
        klass.new(dummy).instantiate
      end

      expect(&proc).to raise_error(mapping_error_class)
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

  describe '#map' do
    it 'should call external mapper if supplied' do
      mapper = ->(*) {}
      type = klass.new(dummy)
      type.mapper = mapper
      expect(mapper).to receive(:call)
      type.map(nil) {}
    end

    it 'should iterate through attributes if no mapper is supplied' do
      value = 12
      object = {}
      attribute = double(name: :value)
      expect(attribute).to receive(:extract).and_return(value)
      expect(attribute).to receive(:set).and_return(nil)
      type = klass.new(dummy)
      type.attributes[:value] = attribute
      proc = lambda do |block|
        type.map(object, &block)
      end
      expect(&proc).to yield_with_args(attribute, value)
    end
  end
end
