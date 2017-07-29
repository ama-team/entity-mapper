# frozen_string_literal: true

require_relative '../../../../../lib/mapper/type/resolver'
require_relative '../../../../../lib/mapper/type/concrete'
require_relative '../../../../../lib/mapper/type/registry'
require_relative '../../../../../lib/mapper/type/any'
require_relative '../../../../../lib/mapper/exception/compliance_error'

klass = ::AMA::Entity::Mapper::Type::Resolver
type_class = ::AMA::Entity::Mapper::Type::Concrete
registry_class = ::AMA::Entity::Mapper::Type::Registry
compliance_error_class = ::AMA::Entity::Mapper::Exception::ComplianceError
any_type = ::AMA::Entity::Mapper::Type::Any::INSTANCE

describe klass do
  let(:entity_class) do
    Class.new do
      def self.to_s
        'Entity'
      end
    end
  end

  let(:entity) do
    type_class.new(entity_class)
  end

  let(:parametrized_class) do
    Class.new do
      def self.to_s
        'Parametrized'
      end
    end
  end

  let(:parametrized) do
    type_class.new(parametrized_class).tap do |type|
      type.attribute!(:value, type.parameter!(:T))
    end
  end

  let(:hash_class) do
    Class.new do
      def self.to_s
        'Hash (not really)'
      end
    end
  end

  let(:hash) do
    type_class.new(hash_class).tap do |type|
      type.attribute!(:key, type.parameter!(:K))
      type.attribute!(:value, type.parameter!(:V))
    end
  end

  let(:registry) do
    registry_class.new.tap do |registry|
      %i[entity parametrized hash].each do |type|
        registry.register(send(type))
      end
    end
  end

  let(:resolver) do
    klass.new(registry)
  end

  describe '#resolve' do
    it 'passes through simple type' do
      type = resolver.resolve(entity)
      expect(type).to eq(entity)
    end

    it 'passes through resolved type combination' do
      parameter = parametrized.parameters[:T]
      definition = [parametrized, parameter => entity]
      expectation = parametrized.resolve_parameter(parameter, [entity])
      type = resolver.resolve(definition)
      expect(type).to eq(expectation)
    end

    it 'passes through nested resolved type combination' do
      parameter = parametrized.parameters[:T]
      definition = [parametrized, parameter => [parametrized, parameter => entity]]
      intermediate = parametrized.resolve_parameter(parameter, [entity])
      expectation = intermediate.resolve_parameter(parameter, intermediate)
      type = resolver.resolve(definition)
      expect(type).to eq(expectation)
    end

    it 'resolves plain class' do
      type = resolver.resolve(entity.type)
      expect(type).to eq(entity)
    end

    it 'resolves parameter' do
      definition = [parametrized, T: entity]
      parameter = parametrized.parameters[:T]
      expectation = parametrized.resolve_parameter(parameter, [entity])
      type = resolver.resolve(definition)
      expect(type).to eq(expectation)
    end

    it 'resolves complex raw definition' do
      definition = [hash, K: Symbol, V: [[parametrized, T: entity], entity]]
      parameter = parametrized.parameters[:T]
      intermediate = parametrized.resolve_parameter(parameter, [entity])
      parameter = hash.parameters[:V]
      intermediate = hash.resolve_parameter(parameter, [intermediate, entity])
      parameter = hash.parameters[:K]
      replacement = type_class.new(Symbol)
      expectation = intermediate.resolve_parameter(parameter, replacement)
      type = resolver.resolve(definition)

      expect(type).to eq(expectation)
    end

    it 'raises on invalid parameters definition' do
      proc = lambda do
        resolver.resolve([entity, 12])
      end

      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'raises on invalid parameter key' do
      proc = lambda do
        resolver.resolve([parametrized, 12 => entity])
      end

      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'raises on non-existent type parameter' do
      proc = lambda do
        resolver.resolve([parametrized, Z: entity])
      end

      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'raises on foreign type parameter' do
      parameter = hash.parameters[:K]
      proc = lambda do
        resolver.resolve([parametrized, parameter => entity])
      end

      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'raises on invalid type' do
      proc = lambda do
        resolver.resolve('cucumber')
      end

      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'processes Any type as any other' do
      resolver.resolve([parametrized, T: any_type])
    end
  end
end
