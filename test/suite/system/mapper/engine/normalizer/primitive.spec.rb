# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/engine/normalizer/primitive'

klass = ::AMA::Entity::Mapper::Engine::Normalizer::Primitive

describe klass do
  let(:normalizer) do
    klass.new
  end

  describe '#normalize' do
    variants = {
      nil: nil,
      integer: 1,
      float: 1.0,
      string: 'string',
      symbol: :symbol,
      true: true,
      false: false,
      array: [1, true],
      hash: { x: 12 }
    }

    variants.each do |name, value|
      it "should normalize #{name} as itself" do
        expect(normalizer.normalize(value)).to eq(value)
      end
    end
  end
end
