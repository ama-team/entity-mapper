# frozen_string_literal: true

require_relative '../../../../../lib/mapper/type/registry'
require_relative '../../../../../lib/mapper/type/concrete'

klass = ::AMA::Entity::Mapper::Type::Registry
type_klass = ::AMA::Entity::Mapper::Type::Concrete

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

  let(:sideway) do
    Class.new
  end

  let(:registry) do
    klass.new.tap do |registry|
      %i[top middle_module middle bottom_module bottom sideway].each do |type|
        registry.register(type_klass.new(send(type)))
      end
    end
  end

  describe '#for' do
    it 'should return all types in ascending order for bottom class' do
      types = registry.for(bottom)
      classes = types.map(&:type)
      expectation = [bottom, middle, top, bottom_module, middle_module]
      expect(classes).to eq(expectation)
    end

    it 'should return top and middle types for middle class' do
      types = registry.for(middle)
      classes = types.map(&:type)
      expectation = [middle, top, middle_module]
      expect(classes).to eq(expectation)
    end

    it 'should return top type only for top class' do
      expect(registry.for(top).map(&:type)).to eq([top])
    end
  end
end
