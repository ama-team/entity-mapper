# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/api/default/normalizer'

klass = ::AMA::Entity::Mapper::API::Default::Normalizer

describe klass do
  let(:normalizer) do
    klass.new
  end

  let(:entity) do
    Class.new do
      attr_accessor :id
      attr_accessor :number
      attr_accessor :virtual
      attr_accessor :sensitive
    end
  end

  let(:type) do
    attributes = {
      id: double(name: :id, virtual: false, sensitive: false),
      number: double(name: :number, virtual: false, sensitive: false),
      virtual: double(name: :virtual, virtual: true, sensitive: false),
      sensitive: double(name: :sensitive, virtual: false, sensitive: true)
    }
    double(type: entity, attributes: attributes)
  end

  describe '#normalize' do
    it 'normalizes instance as a hash of instance variables' do
      instance = entity.new
      instance.id = :josh
      instance.number = 12
      expectation = { id: instance.id, number: instance.number }
      result = normalizer.normalize(instance, type)
      expect(result).to be_a(Hash)
      expect(result).to eq(expectation)
    end

    it 'does not normalize sensitive and virtual attributes' do
      instance = entity.new
      instance.virtual = :virtual
      instance.sensitive = :sensitive
      result = normalizer.normalize(instance, type)
      expect(result).not_to include(:virtual, :sensitive)
    end
  end
end
