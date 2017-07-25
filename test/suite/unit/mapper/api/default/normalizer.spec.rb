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
    end
  end

  describe '#normalize' do
    it 'should normalize instance as a hash of instance variables' do
      instance = entity.new
      instance.id = :josh
      instance.number = 12
      expectation = { id: instance.id, number: instance.number }
      type = double(type: entity)
      result = normalizer.normalize(instance, type)
      expect(result).to be_a(Hash)
      expect(result).to eq(expectation)
    end
  end
end
