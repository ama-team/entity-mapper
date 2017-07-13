# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/engine/normalizer/entity'
require_relative '../../../../../../lib/mapper/type/registry'
require_relative '../../../../../../lib/mapper/type/concrete'

klass = ::AMA::Entity::Mapper::Engine::Normalizer::Entity
registry_klass = ::AMA::Entity::Mapper::Type::Registry
type_klass = ::AMA::Entity::Mapper::Type::Concrete

describe klass do
  let(:simple_entity_klass) do
    Class.new do
      def initialize
        @value = 1
      end

      def self.to_s
        'simple_entity_klass'
      end
    end
  end

  let(:normalized_entity_klass) do
    Class.new do
      def initialize
        @value = 1
      end

      def self.to_s
        'normalized_entity_klass'
      end
    end
  end

  let(:fallback_normalized_entity_klass) do
    Class.new do
      attr_accessor :value

      def initialize
        @value = 1
      end

      def self.to_s
        'fallback_normalized_entity_klass'
      end
    end
  end

  let(:sensitive_entity_klass) do
    Class.new do
      def initialize
        @value = 1
      end

      def self.to_s
        'sensitive_entity_klass'
      end
    end
  end

  let(:simple_entity_type) do
    type = type_klass.new(simple_entity_klass)
    type.attribute(:value, Integer)
    type
  end

  let(:normalized_entity_type) do
    type = type_klass.new(normalized_entity_klass)
    type.attribute(:value, Integer)
    type.normalizer = lambda do |*|
      { value: 123 }
    end
    type
  end

  let(:fallback_normalized_entity_type) do
    type = type_klass.new(fallback_normalized_entity_klass)
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
    type = type_klass.new(sensitive_entity_klass)
    type.attribute(:value, Integer, sensitive: true)
    type
  end

  let(:registry) do
    registry_klass.new.tap do |registry|
      %i[simple normalized sensitive fallback_normalized].each do |type|
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
      expect(normalizer.normalize(simple_entity_klass.new)).to eq(expectation)
    end

    it 'should normalize sensitive entity as empty hash' do
      expect(normalizer.normalize(sensitive_entity_klass.new)).to eq({})
    end

    it 'should use provided normalizer' do
      expectation = { value: 123 }
      result = normalizer.normalize(normalized_entity_klass.new)
      expect(result).to eq(expectation)
    end

    it 'should allow provided normalizer to fall back on default normalizer' do
      expectation = { value: 123, extra: 123 }
      result = normalizer.normalize(fallback_normalized_entity_klass.new)
      expect(result).to eq(expectation)
    end
  end
end
