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
    end
  end

  describe '#enumerate' do
    it 'should enumerate type attributes' do
      id = double(name: :id)
      number = double(name: :number)
      type = double(type: double, attributes: { id: id, number: number })
      instance = entity.new
      instance.id = :j
      instance.number = 12
      proc = lambda do |block|
        enumerator.enumerate(instance, type).each(&block)
      end
      args = [[id, instance.id, anything], [number, instance.number, anything]]
      expect(&proc).to yield_successive_args(*args)
    end
  end
end
