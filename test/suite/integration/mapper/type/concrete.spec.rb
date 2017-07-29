# frozen_string_literal: true

require_relative '../../../../../lib/mapper/type/concrete'
require_relative '../../../../../lib/mapper/exception/compliance_error'

klass = ::AMA::Entity::Mapper::Type::Concrete
compliance_error_class = ::AMA::Entity::Mapper::Exception::ComplianceError

describe klass do
  let(:dummy_class) do
    Class.new do
      attr_accessor :id
      attr_accessor :value
      attr_accessor :_metadata

      def self.to_s
        'Dummy'
      end
    end
  end

  let(:parametrized) do
    type = Class.new do
      def self.to_s
        'Parametrized'
      end
    end
    klass.new(type).tap do |instance|
      instance.attribute!(:id, Symbol)
      instance.attribute!(:value, :T)
    end
  end

  let(:resolved) do
    type = Class.new do
      attr_accessor :id
      def self.to_s
        'Resolved'
      end
    end
    klass.new(type).tap do |instance|
      instance.attribute!(:id, Symbol)
    end
  end

  let(:nested) do
    type = Class.new do
      def self.to_s
        'Nested'
      end
    end
    klass.new(type).tap do |instance|
      instance.attribute!(:id, Symbol)
      parameter = instance.parameter!(:T)
      attribute = instance.attribute!(:value, parametrized)
      attribute.types.first.attributes[:value].types[0] = parameter
      attribute.types.first.parameters[:T] = parameter
    end
  end

  describe '#resolve' do
    it 'should create new resolved type on call' do
      type = parametrized
      expect(type.resolved?).to be false
      derivation = type.resolve(type.parameter!(:T) => [resolved])
      expect(derivation.resolved?).to be true
    end

    it 'should recursively resolve types' do
      type = nested
      expect(type.resolved?).to be false
      derivation = type.resolve(type.parameter!(:T) => [resolved])
      expect(derivation.resolved?).to be true
    end
  end

  describe '#resolve_parameter' do
    it 'substitutes parameter with another parameter' do
      substitution = resolved.parameter!(:E)
      parameter = parametrized.parameters[:T]
      type = parametrized.resolve_parameter(parameter, substitution)
      expect(type.parameters[:T]).to eq(substitution)
      expect(type.attributes[:value].types).to include(substitution)
    end

    it 'substitutes parameter with array of types' do
      substitution = [resolved]
      parameter = parametrized.parameters[:T]
      type = parametrized.resolve_parameter(parameter, substitution)
      expect(type.parameters[:T]).to eq(substitution)
      expect(type.attributes[:value].types).to eq(substitution)
    end

    it 'substitutes parameter with another type' do
      substitution = resolved
      parameter = parametrized.parameters[:T]
      type = parametrized.resolve_parameter(parameter, substitution)
      expect(type.parameters[:T]).to eq([substitution])
      expect(type.attributes[:value].types).to include(substitution)
    end

    it 'raises compliance error if invalid parameter has been passed' do
      proc = lambda do
        parametrized.resolve_parameter(double, resolved)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'raises compliance error if invalid substitution has been passed' do
      proc = lambda do
        parametrized.resolve_parameter(parametrized.parameters[:T], double)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'raises compliance error if array of parameters has been passed' do
      substitution = [resolved.parameter!(:E)]
      parameter = parametrized.parameters[:T]
      proc = lambda do
        parametrized.resolve_parameter(parameter, substitution)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end
  end

  describe '#factory' do
    it 'should provide default factory if none was set' do
      type = klass.new(dummy_class)
      factory = type.factory
      expect(factory.create(type)).to be_a(dummy_class)
    end
  end

  describe '#enumerator' do
    it 'should provide default enumerator' do
      type = klass.new(dummy_class)
      type.attributes[:id] = double(name: :id, virtual: false)
      specimen = dummy_class.new
      specimen.id = :symbol
      proc = lambda do |handler|
        type.enumerator.enumerate(specimen, type).each(&handler)
      end
      args = [type.attributes[:id], specimen.id, anything]
      expect(&proc).to yield_with_args(args)
    end
  end

  describe '#injector' do
    it 'should provide default injector' do
      type = klass.new(dummy_class)
      object = dummy_class.new
      doubler = double(name: :id, virtual: false)
      type.injector.inject(object, type, doubler, 12, doubler)
      expect(object.instance_variable_get(:@id)).to eq(12)
    end
  end

  describe '#normalizer' do
    it 'provides default normalizer' do
      object = dummy_class.new
      object.id = :identifier
      result = resolved.normalizer.normalize(object, resolved)
      expect(result).to eq(id: object.id)
    end
  end

  describe '#denormalizer' do
    it 'provides default denormalizer' do
      data = { id: :identifier }
      result = resolved.denormalizer.denormalize(data, resolved)
      expect(result).to be_a(resolved.type)
      expect(result.id).to eq(data[:id])
    end
  end

  describe '#to_s' do
    it 'displays only class if there are no parameters' do
      expect(klass.new(dummy_class).to_s).to eq(dummy_class.to_s)
    end

    it 'displays parameters in angle brackets' do
      type = klass.new(dummy_class)
      type.parameter!(:A)
      type.parameters[:B] = [klass.new(dummy_class)]
      dummy = dummy_class.to_s
      expect(type.to_s).to eq("#{dummy}<A:?, B:[#{dummy}]>")
    end
  end

  describe '#satisfied_by?' do
    it 'checks if input passes #instance? check first' do
      type = klass.new(dummy_class)
      input = double(is_a?: false)
      expect(type).to receive(:instance?).and_call_original
      expect(type).not_to receive(:enumerator)
      expect(type.satisfied_by?(input)).to be false
    end

    it 'passes call to all attributes using enumerator call' do
      type = klass.new(dummy_class)
      input = double(is_a?: true)
      input.singleton_class.instance_eval do
        attr_accessor :value
      end
      input.value = :value
      attribute = type.attribute!(:value, dummy_class)
      expect(type).to receive(:instance?).and_call_original
      expect(attribute).to receive(:satisfied_by?).and_return(false)
      expect(type.satisfied_by?(input)).to be false
    end
  end
end
