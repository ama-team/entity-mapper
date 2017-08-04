# frozen_string_literal: true

require_relative '../../../../lib/mapper/type'
require_relative '../../../../lib/mapper/error/validation_error'
require_relative '../../../../lib/mapper/error/compliance_error'

klass = ::AMA::Entity::Mapper::Type
validation_error_class = ::AMA::Entity::Mapper::Error::ValidationError
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError

describe klass do
  let(:default) do
    klass.new(Class.new)
  end

  describe '#valid!' do
    it 'does nothing if no violations are reported by validator' do
      default.validator = double(validate: [])
      proc = lambda do
        default.valid!(double, ctx)
      end
      expect(&proc).not_to raise_error
    end

    it 'raises validation error if validator reports violations' do
      violation = 'violation'
      default.validator = double(validate: [violation])
      proc = lambda do
        default.valid!(double, ctx)
      end
      regexp = Regexp.new(violation)
      expect(&proc).to raise_error(validation_error_class, regexp)
    end
  end

  describe '#valid?' do
    it 'returns false if no violations are reported by validator' do
      default.validator = double(validate: [])
      expect(default.valid?(double, ctx)).to be true
    end

    it 'returns true if validator emits violations' do
      default.validator = double(validate: ['violation'])
      expect(default.valid?(double, ctx)).to be false
    end
  end

  describe '#resolve_parameter' do
    it 'raises if invalid parameter is provided' do
      proc = lambda do
        default.resolve_parameter(double, [default])
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'raises if invalid parameter substitution is provided' do
      proc = lambda do
        default.resolve_parameter(default.parameter!(:T), double)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'raises if empty substitution list is provided' do
      proc = lambda do
        default.resolve_parameter(default.parameter!(:T), [])
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'raises if invalid substitution list is provided' do
      proc = lambda do
        default.resolve_parameter(default.parameter!(:T), [double])
      end
      expect(&proc).to raise_error(compliance_error_class)
    end
  end
end
