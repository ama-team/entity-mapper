# frozen_string_literal: true

require_relative '../../../../../lib/mapper/type/concrete'
require_relative '../../../../../lib/mapper/exception/mapping_error'
require_relative '../../../../../lib/mapper/exception/compliance_error'

klass = ::AMA::Entity::Mapper::Type::Concrete
universal_id = :wuff
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError
compliance_error_class = ::AMA::Entity::Mapper::Exception::ComplianceError

describe klass do
  let(:dummy_class) do
    Class.new do
      attr_accessor :id
      attr_accessor :value
      attr_accessor :_metadata
    end
  end

  let(:broken_constructor_class) do
    Class.new do
      def initialize
        raise
      end
    end
  end

  let(:parametrized_constructor_class) do
    Class.new do
      attr_accessor :value

      def initialize(value)
        @value = value
      end
    end
  end

  let(:parametrized) do
    klass.new(Class.new).tap do |instance|
      instance.attribute!(:id, Symbol)
      instance.attribute!(:value, :T)
    end
  end

  let(:resolved) do
    klass.new(dummy_class).tap do |instance|
      instance.attribute!(:id, Symbol)
    end
  end

  let(:unresolved_attribute) do
    klass.new(Class.new).tap do |instance|
      instance.attribute!(:id, Symbol)
      instance.attribute!(:value, parametrized)
    end
  end

  let(:nested) do
    klass.new(Class.new).tap do |instance|
      instance.attribute!(:id, Symbol)
      parameter = instance.parameter!(:T)
      attribute = instance.attribute!(:value, parametrized)
      attribute.types.first.attributes[:value].types[0] = parameter
      attribute.types.first.parameters[:T] = parameter
    end
  end

  let(:mapped) do
    klass.new(dummy_class).tap do |instance|
      instance.attribute!(:id, Symbol)
      instance.attribute!(:_hidden, Symbol)
      instance.mapper = lambda do |entity, *, &block|
        copy = dummy_class.new
        instance.attributes.values.each do |attribute|
          next if attribute.name[0] == '_'
          attribute.set(copy, block.call(attribute, attribute.extract(entity)))
        end
        copy
      end
    end
  end

  let(:factorized) do
    klass.new(dummy_class).tap do |instance|
      instance.factory = lambda do |*|
        dummy_class.new.tap do |entity|
          entity.id = universal_id
        end
      end
    end
  end

  let(:broken_constructor_type) do
    klass.new(broken_constructor_class)
  end

  let(:broken_factory_type) do
    klass.new(dummy_class).tap do |instance|
      instance.factory = lambda do |*|
        raise
      end
    end
  end

  let(:identical_type_pair) do
    described_klass = Class.new
    Array.new(2) do
      klass.new(described_klass).tap do |type|
        type.attribute!(:id, Symbol)
        type.attribute!(:value, :T)
      end
    end
  end

  describe '#resolved?' do
    it 'should return true if no parameters were introduced' do
      expect(klass.new(dummy_class).resolved?).to be true
    end

    it 'should return false if there is at least one unresolved parameter' do
      expect(parametrized.resolved?).to be false
    end

    it 'should return false if there is at least one unresolved attribute' do
      expect(unresolved_attribute.resolved?).to be false
    end

    it 'should return true once all parameters are resolved' do
      type = parametrized
      type.attributes[:value].types = [klass.new(Class.new)]
      expect(type.resolved?).to be true
    end
  end

  describe '#resolve' do
    it 'should create new resolved type on call' do
      type = parametrized
      expect(type.resolved?).to be false
      derivation = type.resolve(type.parameter!(:T) => resolved)
      expect(derivation.resolved?).to be true
    end

    it 'should recursively resolve types' do
      type = nested
      expect(type.resolved?).to be false
      derivation = type.resolve(type.parameter!(:T) => resolved)
      expect(derivation.resolved?).to be true
    end
  end

  describe '#resolved!' do
    it 'should raise error if at least one parameter is unresolved' do
      proc = lambda do
        parametrized.resolved!
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'should raise error if at least one attribute is unresolved' do
      proc = lambda do
        unresolved_attribute.resolved!
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'should not raise error if all parameters and attributes are resolved' do
      type = parametrized
      subject = type.parameter!(:T)
      replacement = klass.new(Class.new)
      derivation = type.resolve(subject => replacement)
      derivation.resolved!
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
        types.first.parameter!(:E)
        expect(types.first).to eq(types.last)
      end
      test_case.step 'introducing new attribute' do
        types.first.attribute!(:bingo, TrueClass, FalseClass)
        expect(types.first).to eq(types.last)
      end
    end
  end

  describe '#clone' do
    it 'should return instance equal to cloned' do
      expect(parametrized.clone).to eq(parametrized)
    end
  end
end
