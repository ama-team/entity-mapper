# frozen_string_literal: true

require_relative '../../../../../lib/mapper/type/any'
require_relative '../../../../../lib/mapper/exception/compliance_error'

klass = ::AMA::Entity::Mapper::Type::Any
compliance_error_class = ::AMA::Entity::Mapper::Exception::ComplianceError

describe klass do
  describe '#eql?' do
    it 'should be equal to other Any type' do
      expect(klass.new).to eq(klass.new)
    end
  end

  describe '#hash' do
    it 'should provide constant hash' do
      expect(klass.new.hash).to eq(klass.new.hash)
    end
  end

  describe '#parameter!' do
    it 'should raise compliance error on #parameter! call' do
      proc = lambda do
        klass.new.parameter!(:id)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end
  end

  describe '#instance?' do
    it 'should return true for any #instance? call' do
      expect(klass.new.instance?(true)).to be true
    end
  end

  describe '#satisfied_by?' do
    it 'should return true for any #satisfied_by? call' do
      expect(klass.new.satisfied_by?(true)).to be true
    end
  end

  describe '#resolve_parameter' do
    it 'should pass through #resolve_parameter call' do
      type = klass.new
      expect(type.resolve_parameter(nil, nil)).to eq(type)
    end
  end

  describe '#to_s' do
    # yes i do pursuit 100% coverage
    it 'should return constant output' do
      expect(klass.new.to_s).to eq(klass.new.to_s)
      expect(klass.new.to_s).to match(/any/i)
    end
  end
end
