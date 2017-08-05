# frozen_string_literal: true

require_relative '../../../../lib/ama-entity-mapper/type'
require_relative '../../../../lib/ama-entity-mapper/error/validation_error'
require_relative '../../../../lib/ama-entity-mapper/error/compliance_error'

klass = ::AMA::Entity::Mapper::Type
validation_error_class = ::AMA::Entity::Mapper::Error::ValidationError
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError

describe klass do
  let(:attribute) do
    double(
      name: :value,
      resolved?: true,
      resolved!: nil
    )
  end

  let(:default) do
    klass.new(Class.new).tap do |instance|
      instance.attributes = { value: attribute }
    end
  end

  let(:context) do
    double(path: nil, advance: nil)
  end

  describe '#initialize' do
    it 'raises if invalid input is passed' do
      proc = lambda do
        klass.new(double)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end
  end

  describe '#resolved?' do
    it 'passes call to attributes' do
      expect(attribute).to receive(:resolved?).exactly(:once).and_return(true)
      expect(default.resolved?).to be true
    end
  end

  describe '#resolved!' do
    it 'passes call to attributes' do
      expect(attribute).to receive(:resolved!).exactly(:once)
      proc = lambda do
        default.resolved!(context)
      end
      expect(&proc).not_to raise_error
    end
  end

  describe '#instance?' do
    it 'returns true if passed object #is_a? type' do
      object = double
      expect(object).to receive(:is_a?).and_return(true)
      expect(default.instance?(object)).to be true
    end

    it 'returns false if passed object fails #is_a? check' do
      object = double
      expect(object).to receive(:is_a?).and_return(false)
      expect(default.instance?(object)).to be false
    end
  end

  describe '#instance!' do
    it 'does not raise if passed object #is_a? type' do
      object = double
      expect(object).to receive(:is_a?).and_return(true)
      proc = lambda do
        default.instance!(object, context)
      end
      expect(&proc).not_to raise_error
    end

    it 'raises if passed object fails #is_a? check' do
      object = double
      expect(object).to receive(:is_a?).and_return(false)
      proc = lambda do
        default.instance!(object, context)
      end
      expect(&proc).to raise_error(validation_error_class)
    end
  end
end
