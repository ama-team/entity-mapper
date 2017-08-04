# frozen_string_literal: true

require_relative '../../../../../lib/mapper/type/registry'
require_relative '../../../../../lib/mapper/type'
require_relative '../../../../../lib/mapper/error/compliance_error'

klass = ::AMA::Entity::Mapper::Type::Registry
type_klass = ::AMA::Entity::Mapper::Type
compliance_error_klass = ::AMA::Entity::Mapper::Error::ComplianceError

describe klass do
  let(:top) do
    Class.new do
      def self.to_s
        'class:top'
      end
    end
  end

  let(:middle_module) do
    Module.new do
      def self.to_s
        'module:middle'
      end
    end
  end

  let(:middle) do
    inclusion = middle_module
    Class.new(top) do
      include inclusion

      def self.to_s
        'class:middle'
      end
    end
  end

  let(:bottom_module) do
    inclusion = middle_module
    Module.new do
      include inclusion
      def self.to_s
        'module:bottom'
      end
    end
  end

  let(:bottom) do
    inclusion = bottom_module
    Class.new(middle) do
      include inclusion

      def self.to_s
        'class:bottom'
      end
    end
  end

  let(:sidecar) do
    Class.new
  end

  let(:unregistered_descendant) do
    Class.new(bottom)
  end

  let(:parametrized_a) do
    type_klass.new(Class.new).tap do |type|
      type.attribute!(:value, type.parameter!(:T))
    end
  end

  let(:parametrized_b) do
    type_klass.new(Class.new).tap do |type|
      type.attribute!(:value, type.parameter!(:T))
    end
  end

  let(:registry) do
    klass.new.tap do |registry|
      %i[top middle_module middle bottom_module bottom sidecar].each do |type|
        registry.register(type_klass.new(send(type)))
      end
      %i[a b].each do |suffix|
        type = "parametrized_#{suffix}"
        registry.register(send(type))
      end
    end
  end

  describe '#select' do
    it 'returns all types in ascending order for bottom class' do
      types = registry.select(bottom)
      classes = types.map(&:type)
      expectation = [bottom, bottom_module, middle, middle_module, top]
      expect(classes).to eq(expectation)
    end

    it 'returns top and middle types for middle class' do
      types = registry.select(middle)
      classes = types.map(&:type)
      expectation = [middle, middle_module, top]
      expect(classes).to eq(expectation)
    end

    it 'returns top type only for top class' do
      expect(registry.select(top).map(&:type)).to eq([top])
    end
  end

  describe '#find' do
    it 'should return bottom class type for bottom class' do
      result = registry.find(bottom)
      expect(result).not_to be_nil
      expect(result.type).to eq(bottom)
    end

    it 'should return nil for unregistered type' do
      expect(registry.find(Class.new)).to be_nil
    end
  end

  describe '#find!' do
    it 'should return bottom class type for bottom class' do
      result = registry.find!(bottom)
      expect(result).not_to be_nil
      expect(result.type).to eq(bottom)
    end

    it 'raises on unregistered type' do
      proc = lambda do
        registry.find!(Class.new)
      end
      expect(&proc).to raise_error(compliance_error_klass)
    end
  end

  describe '#registered?' do
    it 'should return true for registered class' do
      expect(registry.registered?(top)).to eq(true)
    end

    it 'should return false for non-registered class' do
      expect(registry.registered?(Class.new)).to eq(false)
    end
  end

  describe '#resolvable?' do
    it 'should return true for registered class' do
      expect(registry.resolvable?(bottom)).to be(true)
    end

    it 'should return true for class having registered ancestor' do
      expect(registry.resolvable?(unregistered_descendant)).to be(true)
    end

    it 'should return false for class that doesn\'t have any registered ancestors' do
      expect(registry.resolvable?(Class.new)).to be(false)
    end
  end
end
