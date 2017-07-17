# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/exception/mapping_error'
require_relative '../../../../../../lib/mapper/engine/normalizer/object'
require_relative '../../../../../../lib/mapper/engine/context'

klass = ::AMA::Entity::Mapper::Engine::Normalizer::Object
exception_klass = ::AMA::Entity::Mapper::Exception::MappingError
context_klass = ::AMA::Entity::Mapper::Engine::Context

describe klass do
  let(:normalizer) do
    klass.new
  end

  let(:object) do
    waffle = Class.new do
      attr_accessor :x
      attr_accessor :y
      attr_accessor :z

      def initialize
        @x = 1
        @y = 2
        @z = 3
      end

      def to_hash
        intermediate = %i[x y z].map { |key| [key, send(key)] }
        Hash[intermediate]
      end
    end
    waffle.new
  end

  let(:context) do
    context_klass.new
  end

  let(:forbidding_context) do
    options = {
      normalization_method: nil,
      denormalization_method: nil
    }
    context_klass.new(**options)
  end

  describe '#normalize' do
    it 'should normalize object as hash of it\'s instance variables' do
      expect(normalizer.normalize(object, context)).to eq(object.to_hash)
    end

    it 'should use :normalize method' do
      value = { x: 12, z: 13 }
      doubler = double
      allow(doubler).to receive(:normalize).and_return(value).once
      expect(normalizer.normalize(doubler, context)).to eq(value)
    end

    it 'should not use normalization method if forbidden to' do
      subject = object
      def subject.normalize
        'Oh noes'
      end
      context = self.forbidding_context
      expect(normalizer.normalize(subject, context)).to eq(subject.to_hash)
    end

    it 'should wrap encountered exceptions' do
      doubler = double
      allow(doubler).to receive(:normalize).and_raise(RuntimeError)
      expectation = expect do
        normalizer.normalize(doubler, context)
      end
      expectation.to raise_error(exception_klass)
    end
  end
end
