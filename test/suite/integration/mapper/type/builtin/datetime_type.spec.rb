# frozen_string_literal: true

require_relative '../../../../../../lib/ama-entity-mapper/type/builtin/datetime_type'
require_relative '../../../../../../lib/ama-entity-mapper/error/compliance_error'
require_relative '../../../../../../lib/ama-entity-mapper/context'

klass = ::AMA::Entity::Mapper::Type::BuiltIn::DateTimeType
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError
context_class = ::AMA::Entity::Mapper::Context

describe klass do
  let(:type) do
    klass::INSTANCE
  end

  let(:ctx) do
    context_class.new(logger: logger)
  end

  describe '#factory' do
    it 'forbids dummy entity creation' do
      proc = lambda do
        type.factory.create(type, double, ctx)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end
  end

  describe '#normalizer' do
    it 'normalizes DateTime to String' do
      input = DateTime.new
      result = type.normalizer.normalize(input, double, ctx)
      expect(result).to be_a(String)
      expect(DateTime.iso8601(result, 9)).to eq(input)
    end
  end

  describe '#denormalizer' do
    it 'denormalizes DateTime from String' do
      input = DateTime.new
      result = type.denormalizer.denormalize(input.iso8601(3), double, ctx)
      expect(result).to be_a(DateTime)
      expect(result).to eq(input)
    end

    it 'denormalizes DateTime from integer' do
      input = DateTime.now(Date::GREGORIAN).to_time.to_i
      result = type.denormalizer.denormalize(input, double, ctx)
      expect(result).to be_a(DateTime)
      expect(result).to eq(Time.at(input).getgm.to_datetime)
    end
  end
end
