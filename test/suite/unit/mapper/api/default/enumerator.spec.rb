# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/api/default/enumerator'
require_relative '../../../../../../lib/mapper/exception/mapping_error'

klass = ::AMA::Entity::Mapper::API::Default::Enumerator

describe klass do
  let(:enumerator) do
    klass.new
  end

  let(:entity) do
    Class.new do
      attr_accessor :id
      attr_accessor :number
      attr_accessor :virtual
    end
  end

  let(:type) do
    attributes = {
      id: double(name: :id, virtual: false),
      number: double(name: :number, virtual: false),
      virtual: double(name: :virtual, virtual: true)
    }
    double(type: double, attributes: attributes)
  end

  describe '#enumerate' do
    it 'should enumerate type attributes' do
      instance = entity.new
      instance.id = :j
      instance.number = 12
      args = enumerator.enumerate(instance, type).map do |attribute, value, *|
        [attribute, value]
      end
      expectation = [
        [type.attributes[:id], instance.id],
        [type.attributes[:number], instance.number]
      ]
      expectation.each do |sample|
        expect(args).to include(sample)
      end
    end

    it 'does not enumerate virtual attributes' do
      instance = entity.new
      instance.virtual = :virtual
      attributes = enumerator.enumerate(instance, type).map do |attribute, *|
        attribute
      end
      expect(attributes).not_to include(type.attributes[:virtual])
    end
  end
end
