# frozen_string_literal: true

require_relative '../../../../lib/mapper/type'
require_relative '../../../../lib/mapper/exception/compliance_error'
require_relative '../../../../lib/mapper/exception/mapping_error'

klass = ::AMA::Entity::Mapper::Type
compliance_error_class = ::AMA::Entity::Mapper::Exception::ComplianceError
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError

describe klass do
  let(:default) do
    Class.new(klass) do
      attr_accessor :attributes
      attr_accessor :parameters

      def initialize
        @attributes = {}
        @parameters = {}
      end

      def to_s
        'default test type'
      end
    end
  end

  let(:dummy) do
    default.new
  end

  describe '#parameters' do
    it 'should return same empty has unless overriden' do
      type = klass.new
      type.parameters[:value] = double(owner: nil, id: :value)
      expect(type.parameters).to eq({})
    end
  end

  describe '#parameter?' do
    it 'should return true if #parameters output contains such parameter' do
      dummy.parameters[:value] = double(owner: nil, id: :value)
      expect(dummy.parameter?(:value)).to be true
    end

    it 'should return false if #parameters output doesn\'t contain such parameter' do
      expect(dummy.parameter?(:value)).to be false
    end
  end

  describe '#attributes' do
    it 'should return same empty has unless overriden' do
      type = klass.new
      type.attributes[:id] = double(name: :id, type: nil)
      expect(type.attributes).to eq({})
    end
  end

  describe 'attribute?' do
    it 'should return true if #attributes output contains such attribute' do
      dummy.attributes[:id] = double(name: :id, type: nil)
      expect(dummy.attribute?(:id)).to be true
    end

    it 'should return false if #attributes output doesn\'t contain such attribute' do
      expect(dummy.attribute?(:id)).to be false
    end
  end

  describe '#resolved?' do
    it 'should return true if there are no unresolved attributes' do
      dummy.attributes = {
        id: double(name: :id, types: [], resolved?: true),
        name: double(name: :name, types: [], resolved?: true)
      }
      expect(dummy.resolved?).to be true
    end

    it 'should return false if there is at least one unresolved attribute' do
      dummy.attributes = {
        id: double(name: :id, types: [], resolved?: true),
        name: double(name: :name, types: [], resolved?: false)
      }
      expect(dummy.resolved?).to be false
    end
  end

  describe '#resolved!' do
    it 'should raise compliance error if current type has any parameters' do
      dummy.parameters = { value: double(owner: dummy, id: :value) }
      proc = lambda do
        dummy.resolved!
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'should pass call to attributes if current type has no parameters' do
      attribute = double(resolved!: nil)
      expect(attribute).to receive(:resolved!).exactly(:once)
      dummy.attributes = { id: attribute }
      dummy.resolved!
    end
  end

  describe 'instance!' do
    it 'should not raise error if #instance? returns true' do
      allow(dummy).to receive(:instance?).and_return(true)
      proc = lambda do
        dummy.instance!(nil)
      end
      expect(&proc).not_to raise_error
    end

    it 'should raise mapping error if #instance? returns false' do
      allow(dummy).to receive(:instance?).and_return(false)
      proc = lambda do
        dummy.instance!(nil)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end
  end
end