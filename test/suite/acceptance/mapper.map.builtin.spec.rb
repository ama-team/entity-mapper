# frozen_string_literal: true

require 'date'

require_relative '../../../lib/ama-entity-mapper'
require_relative '../../../lib/ama-entity-mapper/error/mapping_error'

klass = ::AMA::Entity::Mapper
mapping_error_class = ::AMA::Entity::Mapper::Error::MappingError

describe klass do
  describe '#map' do
    describe '> builtin types' do
      describe '> DateTime' do
        it 'maps is8601 string to DateTime and vice versa' do
          denormalized1 = klass.map('2017-08-01T00:00:00.123Z', DateTime)
          normalized1 = klass.map(denormalized1, String)
          denormalized2 = klass.map(normalized1, DateTime)
          normalized2 = klass.map(denormalized2, String)
          expect(denormalized1).to eq(denormalized2)
          expect(normalized1).to eq(normalized2)
        end

        it 'maps timestamp to DateTime' do
          timestamp = 1_500_000_000
          expectation = Time.at(timestamp).to_datetime
          expect(klass.map(timestamp, DateTime)).to eq(expectation)
        end

        it 'rejects to map anything but string/integer to DateTime' do
          proc = lambda do
            klass.map({}, DateTime)
          end
          expect(&proc).to raise_error(mapping_error_class)
        end
      end

      describe '> Rational' do
        it 'maps string to rational and vice versa' do
          denormalized1 = klass.map('2.3', Rational)
          normalized1 = klass.map(denormalized1, String)
          denormalized2 = klass.map(normalized1, Rational)
          normalized2 = klass.map(denormalized2, String)
          expect(denormalized1).to eq(denormalized2)
          expect(normalized1).to eq(normalized2)
        end

        it 'rejects to map anything but string to rational' do
          proc = lambda do
            klass.map({}, Rational)
          end
          expect(&proc).to raise_error(mapping_error_class)
        end
      end
    end
  end
end
