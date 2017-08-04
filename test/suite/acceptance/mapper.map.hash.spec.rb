# frozen_string_literal: true

require_relative '../../../lib/mapper'
require_relative '../../../lib/mapper/dsl'
require_relative '../../../lib/mapper/type/any'
require_relative '../../../lib/mapper/context'
require_relative '../../../lib/mapper/error/mapping_error'

klass = ::AMA::Entity::Mapper

describe klass do
  describe '#map' do
    describe '> Hash' do
      it 'converts keys and values as necessary' do
        input = { 'x' => nil, 0 => 1 }
        expectation = { x: nil, 0.0 => 1 }
        type = [Hash, K: [Symbol, Float], V: [NilClass, Integer]]
        expect(klass.map(input, type, logger: logger)).to eq(expectation)
      end

      it 'converts deeply nested keys and values' do
        input = {
          alpha: {
            id: 'alpha',
            value: 10.0
          }
        }
        expectation = {
          alpha: {
            id: :alpha,
            value: 10
          }
        }
        type = [Hash, K: Symbol, V: [Hash, K: Symbol, V: [Symbol, Integer]]]
        expect(klass.map(input, type, logger: logger)).to eq(expectation)
      end
    end
  end
end
