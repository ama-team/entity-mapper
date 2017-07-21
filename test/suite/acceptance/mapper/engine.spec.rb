# frozen_string_literal: true

require_relative '../../../../lib/mapper/engine'
require_relative '../../../../lib/mapper/type/registry'
require_relative '../../../../lib/mapper/type/concrete'
require_relative '../../../../lib/mapper/type/hardwired/hash_type'
require_relative '../../../../lib/mapper/type/hardwired/enumerable_type'

klass = ::AMA::Entity::Mapper::Engine
type_class = ::AMA::Entity::Mapper::Type::Concrete
registry_class = ::AMA::Entity::Mapper::Type::Registry

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

  let(:hash_type) do
    ::AMA::Entity::Mapper::Type::Hardwired::HashType.new
  end

  let(:enumerable_type) do
    ::AMA::Entity::Mapper::Type::Hardwired::EnumerableType.new
  end

  let(:registry) do
    registry_class.new.tap do |registry|
      registry.register(hash_type)
      registry.register(enumerable_type)
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
    end
  end
end
