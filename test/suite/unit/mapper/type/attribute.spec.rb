# frozen_string_literal: true

require_relative '../../../../../lib/ama-entity-mapper/type/attribute'
require_relative '../../../../../lib/ama-entity-mapper/error/compliance_error'
require_relative '../../../../../lib/ama-entity-mapper/error/validation_error'

klass = ::AMA::Entity::Mapper::Type::Attribute
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError
validation_error_class = ::AMA::Entity::Mapper::Error::ValidationError

describe klass do
  let(:type) do
    double(
      type: Class.new,
      is_a?: true,
      to_s: 'Type',
      to_def: 'Type',
      resolved?: true,
      resolved!: nil
    )
  end

  let(:other_type) do
    double(
      type: Class.new,
      is_a?: true,
      to_s: 'OtherType',
      to_def: 'OtherType',
      resolved?: true,
      resolved!: nil
    )
  end

  let(:context) do
    double(
      path: nil,
      advance: nil
    )
  end

  let(:instance) do
    klass.new(type, :id, type)
  end

  let(:attribute) do
    instance
  end

  describe '#eql?' do
    it 'should return true if owners and names match' do
      instances = Array.new(2) do
        klass.new(type, :id, type)
      end
      expect(instances.first).to eq(instances.last)
    end

    it 'should return false if owners differ' do
      instances = [type, other_type].map do |type|
        klass.new(type, :id, type)
      end
      expect(instances.first).not_to eq(instances.last)
    end

    it 'should return false if names differ' do
      instances = Array.new(2) do |index|
        klass.new(type, index.to_s.to_sym, type)
      end
      expect(instances.first).not_to eq(instances.last)
    end
  end

  describe '#hash' do
    it 'should return equal values for identical instances' do
      instances = Array.new(2) do
        klass.new(type, :id, type)
      end
      expect(instances.first.hash).to eq(instances.last.hash)
    end
  end

  describe '#initialize' do
    it 'should raise error if provided owner is not a type' do
      proc = lambda do
        klass.new(double(is_a?: false), :id, type)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'should raise error if not a symbol is passed as name' do
      proc = lambda do
        klass.new(type, 'id', type)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'should raise error if invalid type is specified' do
      proc = lambda do
        klass.new(type, :id, double(is_a?: false))
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'should raise error if no types are specified' do
      proc = lambda do
        klass.new(type, :id)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end
  end

  describe '#resolved?' do
    it 'should pass call through onto types' do
      expect(type).to receive(:resolved?).at_least(:once)
      attribute = klass.new(type, :id, type)
      expect(attribute.resolved?).to be true
    end
  end

  describe '#resolved!' do
    it 'should pass call through onto types' do
      expect(type).to receive(:resolved!).at_least(:once)
      attribute = klass.new(type, :id, type)
      proc = lambda do
        attribute.resolved!
      end
      expect(&proc).not_to raise_error
    end
  end

  describe '#resolve_parameter' do
    it 'should clone itself and pass the call to types' do
      expect(type).to receive(:resolve_parameter).and_return(type).exactly(:once)
      attribute = klass.new(type, :id, type)
      clone = attribute.resolve_parameter(:T, nil)
      expect(clone).to eq(attribute)
      expect(clone).not_to equal(attribute)
    end
  end

  describe '#validator_block' do
    it 'accepts validator via block' do
      value = double
      proc = lambda do |listener|
        attribute.validator_block(&listener)
        attribute.validator.validate(value, attribute, context)
      end
      expect(&proc).to yield_with_args(value, attribute, context)
    end
  end

  describe '#violations' do
    it 'calls validator with provided value, self and context' do
      attribute = klass.new(type, :id, type)
      value = double
      validator = double
      result = double
      match = receive(:validate)
        .with(value, attribute, context)
        .and_return(result)
      expect(validator).to(match)
      attribute.validator = validator
      expect(attribute.violations(value, context)).to eq(result)
    end
  end

  describe '#valid?' do
    it 'returns true if validator returns no violations' do
      attribute.validator = double(validate: [])
      expect(attribute.valid?(double, context)).to be true
    end

    it 'returns false if validator returns at least one violation' do
      attribute.validator = double(validate: ['violation'])
      expect(attribute.valid?(double, context)).to be false
    end
  end

  describe '#valid!' do
    it 'doesn\'t raise if validator returns no violations' do
      attribute.validator = double(validate: [])
      proc = lambda do
        attribute.valid!(double, context)
      end
      expect(&proc).not_to raise_error
    end

    it 'raises validation error if validator returns at least one violation' do
      validator = double(validate: ['violation'])
      attribute.validator = validator
      proc = lambda do
        attribute.valid!(double, context)
      end
      expect(&proc).to raise_error(validation_error_class)
    end
  end
end
