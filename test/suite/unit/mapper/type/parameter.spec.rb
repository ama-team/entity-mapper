# frozen_string_literal: true

require_relative '../../../../../lib/ama-entity-mapper/type/parameter'
require_relative '../../../../../lib/ama-entity-mapper/error/compliance_error'

klass = ::AMA::Entity::Mapper::Type::Parameter
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError

describe klass do
  let(:dummy) do
    klass.new(double(type: Class.new), :id)
  end

  let(:context) do
    double(
      path: nil,
      advance: nil
    )
  end

  describe '#instance?' do
    it 'should return false for anything' do
      expect(dummy.instance?(nil)).to be false
    end
  end

  describe '#resolve_parameter' do
    it 'should pass call through' do
      expect(dummy.resolve_parameter(nil, nil)).to eq(dummy)
    end
  end

  describe '#eql?' do
    it 'should not be equal to instance with another owner' do
      expect(klass.new(:alpha, nil)).not_to eq(klass.new(:beta, nil))
    end

    it 'should not be equal to instance with another id' do
      expect(klass.new(nil, :alpha)).not_to eq(klass.new(nil, :beta))
    end

    it 'should be equal to another instance with same owner and id' do
      expect(klass.new(:a, :b)).to eq(klass.new(:a, :b))
    end
  end

  describe '#hash' do
    it 'should generate same hash for types with same owner and id' do
      owner = double(type: Class.new)
      expect(klass.new(owner, :id).hash).to eq(klass.new(owner, :id).hash)
    end
  end

  describe '#resolved?' do
    it 'should always return false' do
      expect(dummy.resolved?).to be false
    end
  end

  describe '#resolved!' do
    it 'should raise compliance error' do
      proc = lambda do
        klass.new(double(type: Class.new), :value).resolved!
      end
      expect(&proc).to raise_error(compliance_error_class)
    end
  end

  describe '#to_def' do
    it 'returns consistent definition' do
      expect(klass.new(double(type: :A), :id).to_def).to eq('A.id')
    end
  end
end
