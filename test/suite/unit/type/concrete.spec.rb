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

  describe '#factory' do
    it 'should provide default factory if none was set' do
      type = klass.new(dummy)
      factory = type.factory
      expect(factory.create).to be_a(dummy)
    end

    it 'should wrap error from custom factory' do
      type = klass.new(Class.new).tap do |instance|
        factory = Object.new
        factory.define_singleton_method :create do |*|
          raise 'woot'
        end
        instance.factory = factory
      end

      proc = lambda do
        type.factory.create
      end

      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'should provide informational error if user passed class with parameterful #initialize()' do
      dummy = Class.new do
        def initialize(_) end
      end

      proc = lambda do
        klass.new(dummy).factory.create
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
        klass.new(dummy).factory.create
      end

      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'should wrap invalid #create() factory method signature' do
      type = klass.new(dummy)
      factory = Object.new
      factory.define_singleton_method(:create) { |a, b, c| }
      type.factory = factory
      proc = lambda do
        type.factory.create
      end
      expect(&proc).to raise_error(mapping_error_class, /interface|contract/)
    end
  end

  describe '#enumerator' do
    it 'should provide default enumerator' do
      type = klass.new(dummy)
      type.attributes[:id] = double(name: :id)
      proc = lambda do |handler|
        type.enumerator(dummy.new).each(&handler)
      end
      expect(&proc).to yield_with_args([type.attributes[:id], nil, anything])
    end

    it 'should wrap custom enumerator factory in safety wrapper' do
      type = klass.new(dummy)
      type.enumerator = lambda do |_a, _b, _c, _d|
        Enumerator.new do |yielder|
          yielder << [double(name: :id), :admin, nil]
        end
      end
      proc = lambda do
        type.enumerator(nil)
      end
      expect(&proc).to raise_error(mapping_error_class, /interface|contract/)
    end
  end

  describe '#acceptor' do
    it 'should provide default acceptor' do
      type = klass.new(dummy)
      object = dummy.new
      doubler = double(name: :id)
      type.acceptor(object).accept(doubler, 12, doubler)
      expect(object.instance_variable_get(:@id)).to eq(12)
    end

    it 'should wrap custom acceptor factory in safety wrapper' do
      type = klass.new(dummy)
      type.acceptor = ->(_a, _b, _c, _d) {}
      proc = lambda do
        type.acceptor(nil)
      end
      expect(&proc).to raise_error(mapping_error_class, /interface|contract/)
    end
  end

  describe '#extractor' do
    it 'should provide default extractor' do
      type = klass.new(dummy)
      attribute = double(name: :id, type: klass.new(Integer), virtual: false)
      type.attributes[:id] = attribute
      data = { id: 12 }
      proc = lambda do |consumer|
        type.extractor(data).each(&consumer)
      end
      expect(&proc).to yield_with_args([attribute, 12, anything])
    end

    it 'should reject anything but hash when using default extractor' do
      type = klass.new(dummy)
      proc = lambda do
        type.extractor(Object.new)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'should wrap custom extractor wrapper in safety wrapper' do
      type = klass.new(dummy)
      type.extractor = ->(_a, _b, _c, _d) {}
      proc = lambda do
        type.extractor({})
      end
      expect(&proc).to raise_error(mapping_error_class, /interface|contract/)
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
