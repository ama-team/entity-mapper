# frozen_string_literal: true

require_relative '../../../../../lib/mapper/engine/normalizer'
require_relative '../../../../../lib/mapper/exception/mapping_error'
require_relative '../../../../../lib/mapper/context'

klass = ::AMA::Entity::Mapper::Engine::Normalizer
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError

describe klass do
  let(:normalizer) do
    klass.new
  end

  let(:type) do
    double(
      type: double,
      normalizer: double(normalize: nil)
    )
  end

  let(:context) do
    double(path: double(to_s: nil))
  end

  describe '#normalize' do
    it 'delegates all the work to type normalizer' do
      result = double
      expect(type.normalizer).to receive(:normalize).and_return(result)
      expect(normalizer.normalize(double, type, context)).to eq(result)
    end

    it 'wraps non-standard normalizer errors' do
      expect(type.normalizer).to receive(:normalize).and_raise(RuntimeError)
      proc = lambda do
        normalizer.normalize(double, type, context)
      end
      expect(&proc).to raise_error(mapping_error_class)
    end

    it 'passes through internal normalizer errors' do
      error = mapping_error_class.new
      expect(type.normalizer).to receive(:normalize).and_raise(error)
      proc = lambda do
        normalizer.normalize(double, type, context)
      end
      expect(&proc).to raise_error(error)
    end
  end
end
