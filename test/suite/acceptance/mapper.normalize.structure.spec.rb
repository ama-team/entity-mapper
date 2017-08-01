# frozen_string_literal: true

require 'set'

require_relative '../../../lib/mapper'

klass = ::AMA::Entity::Mapper

describe klass do
  describe '#normalize' do
    describe '> structure' do
      describe '> Hash' do
        it 'normalizes to itself if empty' do
          value = {}
          expect(klass.normalize(value, logger: logger)).to eq(value)
        end

        it 'normalizes to itself if filled with primitives' do
          value = { x: 'x', 'x' => nil, 1 => 0.0, 0.0 => 1, false => true }
          expect(klass.normalize(value, logger: logger)).to eq(value)
        end

        it 'normalizes to itself if filled with other structures and primitives' do
          value = {
            x: [1, 2, 3.0],
            y: {
              z: nil
            }
          }
          expect(klass.normalize(value, logger: logger)).to eq(value)
        end
      end

      describe '> Array' do
        it 'normalizes to itself if empty' do
          expect(klass.normalize([], logger: logger)).to eq([])
        end

        it 'normalizes to itself if filled with primitives' do
          value = [:x, 'x', 0.0, 1, true, false, nil]
          expect(klass.normalize(value, logger: logger)).to eq(value)
        end

        it 'normalizes to itself if filled with other structures and primitives' do
          value = [
            1,
            2,
            3.0,
            { z: nil }
          ]
          expect(klass.normalize(value, logger: logger)).to eq(value)
        end
      end

      describe '> Set' do
        it 'normalizes to Array' do
          expect(klass.normalize(Set.new([1]))).to eq([1])
        end
      end
    end
  end
end
