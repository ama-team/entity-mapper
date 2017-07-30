# frozen_string_literal: true

require_relative '../../../../../lib/mapper/engine/denormalizer'
require_relative '../../../../../lib/mapper/exception/mapping_error'
require_relative '../../../../../lib/mapper/exception/compliance_error'

klass = ::AMA::Entity::Mapper::Engine::Denormalizer
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError
compliance_error_class = ::AMA::Entity::Mapper::Exception::ComplianceError

describe klass do
  let(:denormalizer) do
    klass.new
  end

  let(:type) do
    double(
      type: nil,
      denormalizer: double(denormalize: nil),
      instance?: true
    )
  end

  let(:context) do
    double(path: double(to_s: nil))
  end

  describe '#denormalize' do
    it 'delegates all the work to type denormalizer' do
      result = double
      expect(type.denormalizer).to receive(:denormalize).and_return(result)
      expect(denormalizer.denormalize(double, type, context)).to eq(result)
    end

    it 'validates denormalizer returns instance of target type' do
      expect(type).to receive(:instance?).and_return(false)
      proc = lambda do
        denormalizer.denormalize(double, type, context)
      end
      expect(&proc).to raise_error(compliance_error_class)
    end

    it 'wraps type denormalizer errors' do
      expect(type.denormalizer).to receive(:denormalize).and_raise(RuntimeError)
      proc = lambda do
        denormalizer.denormalize(double, type, context)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'passes mapping errors' do
      error = mapping_error_class.new
      expect(denormalizer).to receive(:denormalize).and_raise(error)
      proc = lambda do
        denormalizer.denormalize(double, type, context)
      end
      expect(&proc).to raise_error(error)
    end
  end
end
