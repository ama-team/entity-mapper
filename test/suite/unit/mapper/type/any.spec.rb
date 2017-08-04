# frozen_string_literal: true

require_relative '../../../../../lib/mapper/type/any'
require_relative '../../../../../lib/mapper/error/compliance_error'

klass = ::AMA::Entity::Mapper::Type::Any
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError

describe klass do
  let(:instance) do
    klass::INSTANCE
  end

  let(:context) do
    double(
      path: nil,
      advance: nil
    )
  end

  describe '#eql?' do
    it 'should be equal to other Any type' do
      expect(instance).to eq(klass.new)
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
        instance.parameter!(:id)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end
  end

  describe '#instance?' do
    it 'should return true for any #instance? call' do
      expect(instance.instance?(true)).to be true
    end
  end

  describe '#resolve_parameter' do
    it 'should pass through #resolve_parameter call' do
      expect(instance.resolve_parameter(nil, nil)).to be(instance)
    end
  end

  describe '#to_s' do
    # yes i do pursuit 100% coverage
    it 'should return constant output' do
      expect(klass.new.to_s).to eq(klass.new.to_s)
    end
  end

  describe '#to_def' do
    it 'returns a star' do
      expect(instance.to_def).to eq('*')
    end
  end

  describe '#attributes' do
    it 'always returns empty hash' do
      instance.attributes[:id] = 12
      expect(instance.attributes).to be_empty
    end
  end

  describe '#parameters' do
    it 'always returns empty hash' do
      instance.parameters[:id] = 12
      expect(instance.parameters).to be_empty
    end
  end
end
