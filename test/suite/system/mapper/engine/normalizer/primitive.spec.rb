# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/engine/normalizer/primitive'

klass = ::AMA::Entity::Mapper::Engine::Normalizer::Primitive

describe klass do
  let(:normalizer) do
    klass.new
  end

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

  describe '#normalize' do
    variants.each do |name, value|
      it "should normalize #{name} as itself" do
        expect(normalizer.normalize(value)).to eq(value)
      end
    end
  end

  describe '#supports' do
    variants.values.each do |value|
      it "should support primitive #{value.class}" do
        expect(normalizer.supports(value)).to be(true)
      end
    end

    it 'should not support poro' do
      expect(normalizer.supports(Object.new)).to be(false)
    end
  end
end
