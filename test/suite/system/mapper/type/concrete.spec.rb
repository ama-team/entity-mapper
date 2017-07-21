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
        parametrized.resolve_parameter(double, double)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end
  end
end
