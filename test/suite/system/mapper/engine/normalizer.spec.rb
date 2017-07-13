# frozen_string_literal: true

require 'set'

require_relative '../../../../../lib/mapper/engine/normalizer/primitive'
require_relative '../../../../../lib/mapper/engine/normalizer'
require_relative '../../../../../lib/mapper/type/registry'
require_relative '../../../../../lib/mapper/type/concrete'
require_relative '../../../../../lib/mapper/type/any'

klass = ::AMA::Entity::Mapper::Engine::Normalizer
registry_class = ::AMA::Entity::Mapper::Type::Registry
type_class = ::AMA::Entity::Mapper::Type::Concrete
any_type_class = ::AMA::Entity::Mapper::Type::Any

describe klass do
  let(:entity_class) do
    Class.new do
      attr_accessor :value

      def initialize(value)
        @value = value
      end
    end
  end

  let(:entity_type) do
    type = type_class.new(entity_class)
    type.attribute(:value, any_type_class)
    type
  end

  let(:registry) do
    registry_class.new.tap do |registry|
      registry.register(entity_type)
    end
  end

  let(:normalizer) do
    klass.new(registry)
  end

  let(:nested_entity) do
    intermediate_class = Class.new do
      attr_accessor :value

      def initialize(value)
        @value = value
      end
    end

    entity_class.new(intermediate_class.new(Set.new([1])))
  end

  let(:broken_normalization_class) do
    Class.new do
      def normalize
        raise
      end
    end
  end

  describe '#normalize_recursively' do
    it 'should normalize nested entity as planned' do
      expectation = {
        value: {
          value: [1]
        }
      }
      result = normalizer.normalize_recursively(nested_entity)
      expect(result).to eq(expectation)
    end
  end
end
