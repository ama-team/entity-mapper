# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/handler/entity/enumerator'
require_relative '../../../../../../lib/mapper/error/compliance_error'

klass = ::AMA::Entity::Mapper::Handler::Entity::Enumerator
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError

describe klass do
  let(:enumerator) do
    klass::INSTANCE
  end

  let(:attributes) do
    {
      value: double(
        name: :value,
        virtual: false
      ),
      virtual: double(
        name: :virtual,
        virtual: true
      )
    }
  end

  let(:type) do
    double(
      attributes: attributes
    )
  end

  let(:context) do
    double(
      path: nil,
      advance: nil
    )
  end

  let(:entity) do
    double
  end

  let(:mock) do
    double(enumerate: ::Enumerator.new { |*| })
  end

  let(:wrapped) do
    klass.wrap(mock)
  end

  describe '#enumerate' do
    it 'emits values for existing attributes' do
      value = double
      entity.instance_variable_set(:@value, value)
      proc = lambda do |listener|
        enumerator.enumerate(entity, type, context).each(&listener)
      end
      expect(&proc).to yield_with_args([attributes[:value], value, anything])
    end

    it 'skips attributes without a value' do
      proc = lambda do |listener|
        enumerator.enumerate(entity, type, context).each(&listener)
      end
      expect(&proc).not_to yield_control
    end

    it 'skips virtual attributes' do
      value = double
      entity.instance_variable_set(:@virtual, value)
      proc = lambda do |listener|
        enumerator.enumerate(entity, type, context).each(&listener)
      end
      expect(&proc).not_to yield_control
    end
  end

  describe '.wrap' do
    it 'returns wrapped implementation response' do
      value = double
      expect(mock).to receive(:enumerate).and_return(value)
      expect(wrapped.enumerate(entity, type, context)).to be(value)
    end

    it 'provides fallback-block' do
      value = double
      entity.instance_variable_set(:@value, value)
      expect(mock).to receive(:enumerate) do |e, t, c, &block|
        block.call(e, t, c)
      end
      proc = lambda do |listener|
        wrapped.enumerate(entity, type, context).each(&listener)
      end
      expect(&proc).to yield_with_args([attributes[:value], value, anything])
    end

    it 'passes internal exceptions through' do
      error = compliance_error_class.new
      expect(mock).to receive(:enumerate).and_raise(error)
      proc = lambda do
        wrapped.enumerate(entity, type, context)
      end
      expect(&proc).to raise_error(error)
    end

    it 'wraps unexpected errors' do
      expect(mock).to receive(:enumerate).and_raise(RuntimeError)
      proc = lambda do
        wrapped.enumerate(entity, type, context)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'hints about invalid method signature' do
      expect(mock).to receive(:enumerate).and_raise(ArgumentError)
      proc = lambda do
        wrapped.enumerate(entity, type, context)
      end
      regexp = /interface|contract|signature/i
      expect(&proc).to raise_error(compliance_error_class, regexp)
    end
  end
end
