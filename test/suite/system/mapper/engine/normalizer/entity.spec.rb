# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/engine/normalizer/entity'
require_relative '../../../../../../lib/mapper/type/registry'
require_relative '../../../../../../lib/mapper/type/concrete'
require_relative '../../../../../../lib/mapper/exception/mapping_error'

klass = ::AMA::Entity::Mapper::Engine::Normalizer::Entity
registry_class = ::AMA::Entity::Mapper::Type::Registry
type_class = ::AMA::Entity::Mapper::Type::Concrete
error_class = ::AMA::Entity::Mapper::Exception::MappingError

describe klass do
  factory = lambda do |name|
    let(name) do
      Class.new do
        attr_accessor :value

        def initialize
          @value = 1
        end

        def self.to_s
          name.to_s.tr('_', ' ')
        end
      end
    end
  end

  types = %i[simple normalized fallback_normalized sensitive virtual exploding]
  types.each do |type|
    factory.call(:"#{type}_entity_class")
  end

  let(:simple_entity_type) do
    type = type_class.new(simple_entity_class)
    type.attribute(:value, Integer)
    type
  end

  let(:normalized_entity_type) do
    type = type_class.new(normalized_entity_class)
    type.attribute(:value, Integer)
    type.normalizer = lambda do |*|
      { value: 123 }
    end
    type
  end

  let(:fallback_normalized_entity_type) do
    type = type_class.new(fallback_normalized_entity_class)
    type.attribute(:value, Integer)
    type.normalizer = lambda do |entity, *, &block|
      entity.value = 123
      result = block.call(entity)
      result[:extra] = 123
      result
    end
    type
  end

  let(:sensitive_entity_type) do
    type = type_class.new(sensitive_entity_class)
    type.attribute(:value, Integer, sensitive: true)
    type
  end

  let(:virtual_entity_type) do
    type = type_class.new(virtual_entity_class)
    type.attribute(:value, Integer, virtual: true)
    type
  end

  let(:exploding_entity_type) do
    type = type_class.new(exploding_entity_class)
    type.attribute(:value, Integer, virtual: true)
    type.normalizer = lambda do |*|
      raise
    end
    type
  end

  let(:registry) do
    registry_class.new.tap do |registry|
      types.each do |type|
        registry.register(send("#{type}_entity_type"))
      end
    end
  end

  let(:normalizer) do
    klass.new(registry)
  end

  describe '#normalize' do
    it 'should normalize simple entity as attribute hash' do
      expectation = { value: 1 }
      expect(normalizer.normalize(simple_entity_class.new)).to eq(expectation)
    end

    it 'should not normalize sensitive attributes' do
      expect(normalizer.normalize(sensitive_entity_class.new)).to eq({})
    end

    it 'should not normalize virtual attributes' do
      expect(normalizer.normalize(virtual_entity_class.new)).to eq({})
    end

    it 'should use provided normalizer' do
      expectation = { value: 123 }
      result = normalizer.normalize(normalized_entity_class.new)
      expect(result).to eq(expectation)
    end

    it 'should allow provided normalizer to fall back on default normalizer' do
      expectation = { value: 123, extra: 123 }
      result = normalizer.normalize(fallback_normalized_entity_class.new)
      expect(result).to eq(expectation)
    end

    it 'should wrap encountered errors' do
      expectation = expect do
        normalizer.normalize(exploding_entity_class.new)
      end
      expectation.to raise_error(error_class)
    end
  end
end
