# frozen_string_literal: true

require_relative '../../../../../../lib/ama-entity-mapper/type/builtin/rational_type'
require_relative '../../../../../../lib/ama-entity-mapper/error/compliance_error'
require_relative '../../../../../../lib/ama-entity-mapper/error/mapping_error'
require_relative '../../../../../../lib/ama-entity-mapper/context'

klass = ::AMA::Entity::Mapper::Type::BuiltIn::RationalType
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError
mapping_error_class = ::AMA::Entity::Mapper::Error::MappingError

describe klass do
  let(:type) do
    klass::INSTANCE
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
    it 'normalizes Rational to String' do
      input = Rational(23, 10)
      result = type.normalizer.normalize(input, type, ctx)
      expect(result).to eq('23/10')
    end
  end

  describe '#denormalizer' do
    it 'converts dot string (2.3) to Rational' do
      result = type.denormalizer.denormalize('2.3', type, ctx)
      expect(result).to eq(Rational(23, 10))
    end

    it 'converts fraction string (23/10) to Rational' do
      result = type.denormalizer.denormalize('23/10', type, ctx)
      expect(result).to eq(Rational(23, 10))
    end

    it 'rejects anything else' do
      proc = lambda do
        type.denormalizer.denormalize({}, double, ctx)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end
  end
end
