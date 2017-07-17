# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/engine/denormalizer/object'
require_relative '../../../../../../lib/mapper/exception/mapping_error'
require_relative '../../../../../../lib/mapper/engine/context'

klass = ::AMA::Entity::Mapper::Engine::Denormalizer::Object
error_class = ::AMA::Entity::Mapper::Exception::MappingError
context_class = ::AMA::Entity::Mapper::Engine::Context

describe klass do
  let(:denormalizer) do
    klass.new
  end

  let(:context) do
    context_class.new
  end

  let(:forbidding_context) do
    context_class::FORBIDDING
  end

  let(:simple_class) do
    Class.new do
      attr_accessor :alpha
      attr_accessor :beta
      attr_accessor :gamma
    end
  end

  let(:reader_class) do
    Class.new do
      attr_reader :alpha
      attr_reader :beta
      attr_reader :gamma
    end
  end

  let(:parameterized_initialize_class) do
    Class.new do
      def initialize(alpha)
        @alpha = alpha
      end
    end
  end

  let(:custom_denormalizer_class) do
    Class.new do
      attr_accessor :value

      def self.denormalize(source, *)
        new.tap do |instance|
          instance.value = source
        end
      end
    end
  end

  describe '#denormalize' do
    it 'should instantiate simple class from hash' do
      type = double(type: simple_class)
      source = { alpha: 1, beta: 2, gamma: 3 }
      result = denormalizer.denormalize(source, context, type)
      expect(result).to be_a(type.type)
      source.each do |key, value|
        expect(result.send(key)).to eq(value)
      end
    end

    it 'should instantiate simple class without setters from hash' do
      type = double(type: reader_class)
      source = { alpha: 1, beta: 2, gamma: 3 }
      result = denormalizer.denormalize(source, context, type)
      expect(result).to be_a(type.type)
      source.each do |key, value|
        expect(result.send(key)).to eq(value)
      end
    end

    it 'should raise mapping exception if class #initialize method is not parameterless' do
      type = double(type: parameterized_initialize_class)
      expectation = expect do
        denormalizer.denormalize({}, context, type)
      end
      expectation.to raise_error(error_class)
    end

    it 'should use denormalization class method if allowed to' do
      type = double(type: custom_denormalizer_class)
      source = 12
      result = denormalizer.denormalize(source, context, type)
      expect(result).to be_a(type.type)
      expect(result.value).to eq(source)
    end

    it 'should not use denormalization class method if not allowed to' do
      type = double(type: custom_denormalizer_class)
      source = { value: 12 }
      result = denormalizer.denormalize(source, forbidding_context, type)
      expect(result).to be_a(type.type)
      expect(result.value).to eq(source[:value])
    end

    it 'should raise error if source is not a hash' do
      type = double(type: simple_class)
      expectation = expect do
        denormalizer.denormalize(nil, context, type)
      end
      expectation.to raise_error(error_class)
    end
  end
end
