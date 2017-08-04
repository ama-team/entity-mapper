# frozen_string_literal: true

require_relative '../../../lib/mapper'

klass = ::AMA::Entity::Mapper

describe klass do
  describe '#map' do
    describe '> Object' do
      it 'recognizes unknown object attributes by accessible writers' do
        type = Class.new do
          attr_accessor :alpha
          attr_accessor :beta
        end
        input = { beta: 1, gamma: 2 }

        result = klass.map(input, type, logger: logger)
        expect(result).to be_a(type)
        expect(result.alpha).to be_nil
        expect(result.instance_variables).to include(:@beta)
        expect(result.beta).to eq(1)
        expect(result.instance_variables).not_to include(:@gamma)
      end
    end
  end
end
