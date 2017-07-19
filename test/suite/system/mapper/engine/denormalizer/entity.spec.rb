# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/engine/denormalizer/entity'
require_relative '../../../../../../lib/mapper/exception/mapping_error'
require_relative '../../../../../../lib/mapper/type/registry'
require_relative '../../../../../../lib/mapper/type/concrete'

klass = ::AMA::Entity::Mapper::Engine::Denormalizer::Entity
registry_class = ::AMA::Entity::Mapper::Type::Registry
type_class = ::AMA::Entity::Mapper::Type::Concrete

describe klass do
  factory = lambda do |name|
    let(:"#{name}_entity_class") do
      Class.new do
        attr_accessor :value
        attr_reader :hidden
        attr_accessor :sensitive
        attr_accessor :virtual

        def to_s
          "#{self.class} instance"
        end

        class << self
          define_method :to_s do
            name
          end
        end
      end
    end
  end

  type_factory = lambda do |name, &block|
    let(:"#{name}_entity_type") do
      described_class = send(:"#{name}_entity_class")
      type_class.new(described_class).tap do |type|
        type.attribute!(:value, Integer)
        type.attribute!(:hidden, Integer)
        type.attribute!(:sensitive, Integer, sensitive: true)
        type.attribute!(:virtual, Integer, virtual: true)
        block.call(type) if block
      end
    end
  end

  %i[simple factory denormalizer].each do |type|
    factory.call(type)
  end

  type_factory.call(:simple)

  type_factory.call(:factory) do |type|
    type.factory = lambda do |*|
      type.type.new.tap do |instance|
        instance.virtual = 1
        instance.value = 1
      end
    end
  end

  type_factory.call(:denormalizer) do |type|
    type.denormalizer = lambda do |source, *, &block|
      source.each do |key, value|
        source[key] = value * value
      end
      result = block.call(source)
      result.virtual = 16
      result
    end
  end

  let(:context) do
    nil
  end

  let(:registry) do
    registry_class.new.tap do |registry|
      registry.register(simple_entity_type)
    end
  end

  let(:denormalizer) do
    klass.new(registry)
  end

  describe '#denormalize' do
    it 'should denormalize regular attributes' do
      type = simple_entity_type
      source = { value: 1 }
      result = denormalizer.denormalize(source, context, type)
      expect(result).to be_a(type.type)
      expect(result.value).to eq(1)
    end

    it 'should denormalize sensitive attributes' do
      type = simple_entity_type
      source = { sensitive: 1 }
      result = denormalizer.denormalize(source, context, type)
      expect(result).to be_a(type.type)
      expect(result.sensitive).to eq(1)
    end

    it 'should not denormalize virtual attributes' do
      type = simple_entity_type
      source = { virtual: 1 }
      result = denormalizer.denormalize(source, context, type)
      expect(result).to be_a(type.type)
      expect(result.virtual).to be_nil
    end

    it 'should denormalize attributes without explicit setter' do
      type = simple_entity_type
      source = { hidden: 1 }
      result = denormalizer.denormalize(source, context, type)
      expect(result).to be_a(type.type)
      expect(result.hidden).to eq(1)
    end

    it 'should use provided factory' do
      type = factory_entity_type
      source = {}
      result = denormalizer.denormalize(source, context, type)
      expect(result).to be_a(type.type)
      expect(result.virtual).to eq(1)
    end

    it 'should not overwrite missing values' do
      type = factory_entity_type
      source = {}
      result = denormalizer.denormalize(source, context, type)
      expect(result).to be_a(type.type)
      expect(result.value).to eq(1)
    end

    it 'should use provided denormalizer' do
      type = denormalizer_entity_type
      source = { value: 1, sensitive: 2, hidden: 3 }
      result = denormalizer.denormalize(source, context, type)
      expect(result).to be_a(type.type)
      expect(result.value).to eq(1)
      expect(result.sensitive).to eq(4)
      expect(result.hidden).to eq(9)
      expect(result.virtual).to eq(16)
    end
  end
end
