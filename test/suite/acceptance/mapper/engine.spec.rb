# frozen_string_literal: true

require_relative '../../../../lib/mapper/engine'
require_relative '../../../../lib/mapper/type/registry'
require_relative '../../../../lib/mapper/type/concrete'
require_relative '../../../../lib/mapper/type/any'
require_relative '../../../../lib/mapper/type/hardwired/hash_type'
require_relative '../../../../lib/mapper/type/hardwired/enumerable_type'
require_relative '../../../../lib/mapper/type/hardwired/set_type'
require_relative '../../../../lib/mapper/exception/compliance_error'
require_relative '../../../../lib/mapper/exception/mapping_error'

klass = ::AMA::Entity::Mapper::Engine
type_class = ::AMA::Entity::Mapper::Type::Concrete
registry_class = ::AMA::Entity::Mapper::Type::Registry
compliance_error_class = ::AMA::Entity::Mapper::Exception::ComplianceError
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError

describe klass do
  let(:entity) do
    entity_class = Class.new do
      attr_accessor :id
      attr_accessor :number
      def self.to_s
        'entity'
      end
    end
    type_class.new(entity_class).tap do |type|
      type.attribute!(:id, Symbol)
      type.attribute!(:number, Numeric)
    end
  end

  let(:parametrized_entity) do
    entity_class = Class.new do
      attr_accessor :value
      def self.to_s
        'parametrized entity'
      end
    end
    type_class.new(entity_class).tap do |type|
      type.attribute!(:value, type.parameter!(:T))
    end
  end

  let(:any_type) do
    ::AMA::Entity::Mapper::Type::Any::INSTANCE
  end

  let(:hash_type) do
    ::AMA::Entity::Mapper::Type::Hardwired::HashType.new
  end

  let(:enumerable_type) do
    ::AMA::Entity::Mapper::Type::Hardwired::EnumerableType.new
  end

  let(:set_type) do
    ::AMA::Entity::Mapper::Type::Hardwired::SetType.new
  end

  let(:registry) do
    registry_class.new.tap do |registry|
      registry.register(hash_type)
      registry.register(enumerable_type)
      registry.register(set_type)
      registry.register(entity)
      registry.register(parametrized_entity)
    end
  end

  let(:engine) do
    klass.new(registry)
  end

  describe '#map' do
    describe '> pass-through' do
      candidates = [
        :symbol,
        'String',
        { x: 12 },
        Class.new.new,
        false,
        true,
        nil,
        [:alpha, 'beta', 3],
        Set.new([:whoa])
      ]
      candidates.each do |candidate|
        it "should map #{candidate.inspect} to itself" do
          type = type_class.new(candidate.class)
          expect(engine.map(candidate, type)).to equal(candidate)
        end
      end
    end

    describe '> multi-type' do
      [true, false].each do |value|
        it "should map #{value} to [TrueClass, FalseClass]" do
          types = [TrueClass, FalseClass].map { |type| type_class.new(type) }
          expect(engine.map(value, *types)).to eq(value)
        end
      end
    end

    describe '> entity' do
      it 'should denormalize simple entity from hash' do
        source = { id: :id, number: 12 }
        result = engine.map(source, entity)
        expect(result).to be_a(entity.type)
        expect(result.id).to eq(source[:id])
        expect(result.number).to eq(source[:number])
      end

      it 'should denormalize parametrized entity' do
        source = { value: 12 }
        type = parametrized_entity
        derived = type.resolve(type.parameter!(:T) => type_class.new(Integer))
        result = engine.map(source, derived)
        expect(result).to be_a(derived.type)
        expect(result.value).to eq(12)
      end

      it 'should denormalize nested entity' do
        source = { value: { id: :bill, number: 12 } }
        type = parametrized_entity
        derived = type.resolve(type.parameter!(:T) => entity)
        result = engine.map(source, derived)
        expect(result).to be_a(derived.type)
        expect(result.value).to be_a(entity.type)
        expect(result.value.id).to eq(source[:value][:id])
        expect(result.value.number).to eq(source[:value][:number])
      end

      it 'should denormalize hash of entities' do
        source = {
          'bill' => { id: :bill, number: 12 },
          'francis' => { id: :francis, number: 13 }
        }
        type = hash_type.resolve(K: Symbol, V: entity)
        result = engine.map(source, type)
        expect(result).to be_a(Hash)
        source.each do |key, value|
          expect(result.include?(key.to_sym)).to be true
          entry = result[key.to_sym]
          expect(entry).to be_a(entity.type)
          expect(entry.id).to eq(value[:id])
          expect(entry.number).to eq(value[:number])
        end
      end

      it 'should denormalize array of entities' do
        source = [{ id: :bill, number: 12 }, { id: :francis, number: 13 }]
        type = enumerable_type.resolve(T: entity)
        result = engine.map(source, type)
        expect(result).to be_a(Array)
        result.each_with_index do |entry, index|
          value = source[index]
          expect(entry).to be_a(entity.type)
          expect(entry.id).to eq(value[:id])
          expect(entry.number).to eq(value[:number])
        end
      end

      it 'should denormalize set' do
        source = [1, 1, 2, 2, 3, 3, 4, 4]
        type = set_type.resolve(T: any_type)
        result = engine.map(source, type)
        expect(result).to be_a(Set)
        expect(result).to eq(Set.new([1, 2, 3, 4]))
      end

      it 'should raise compliance error if unresolved type is passed' do
        proc = lambda do
          engine.map({}, parametrized_entity)
        end
        expect(&proc).to raise_error(compliance_error_class)
      end
    end

    describe '> common' do
      it 'should throw compliance error if no types were passed' do
        proc = lambda do
          expect(engine.map({}))
        end
        expect(&proc).to raise_error(compliance_error_class)
      end

      it 'should try next type in case of failure' do
        source = { id: :bill }
        types = [
          set_type.resolve(T: Integer),
          enumerable_type.resolve(T: Integer),
          entity
        ]
        result = engine.map(source, *types)
        expect(result).to be_a(entity.type)
        expect(result.id).to eq(source[:id])
      end

      it 'should throw mapping error if mapping to suggested type is not possible' do
        proc = lambda do
          engine.map([], entity)
        end
        expect(&proc).to raise_error(mapping_error_class)
      end

      it 'should accept class as type in raw form' do
        proc = lambda do
          engine.map('symbol', Symbol)
        end
        expect(&proc).not_to raise_error
        expect(proc.call).to eq(:symbol)
      end

      it 'should accept parameters in raw form' do
        proc = lambda do
          engine.map(Set.new([1]), [Enumerable, T: Integer])
        end
        expect(&proc).not_to raise_error
        expect(proc.call).to eq(Set.new([1]))
      end
    end
  end
end
