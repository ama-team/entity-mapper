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

  let(:nested) do
    klass.new(Class.new).tap do |instance|
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

  describe '#resolve_parameter' do
    it 'should raise compliance error if non-parameter has been passed' do
      proc = lambda do
        parametrized.resolve_parameter(double, resolved)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'should correctly resolve symbols to parameters' do
      type = parametrized.resolve_parameter(:T, resolved)
      expect(type.attributes[:value].types).to eq([resolved])
    end

    it 'should raise compliance error if non-existing parameter is specified' do
      proc = lambda do
        parametrized.resolve_parameter(:Y, Class.new)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'should create concrete type if class is passed as substitution' do
      classee = Class.new
      parameter = parametrized.parameter!(:T)
      resolved = parametrized.resolve_parameter(parameter, classee)
      expect(resolved.attributes[:value].types).to eq([klass.new(classee)])
    end

    it 'should create concrete type if module is passed as substitution' do
      modulee = Module.new
      parameter = parametrized.parameter!(:T)
      resolved = parametrized.resolve_parameter(parameter, modulee)
      expect(resolved.attributes[:value].types).to eq([klass.new(modulee)])
    end

    it 'should raise compliance error if invalid substitution is provided' do
      proc = lambda do
        parametrized.resolve_parameter(parametrized.parameter!(:T), 12)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end
  end
end
