# frozen_string_literal: true

require_relative '../../../lib/ama-entity-mapper'

klass = ::AMA::Entity::Mapper

describe klass do
  describe '#normalize' do
    variants = [0.0, 1, true, false, nil, 'string', :symbol]
    variants.each do |variant|
      describe "> #{variant.class}" do
        it 'is normalized as itself' do
          expect(klass.normalize(variant, logger: logger)).to eq(variant)
        end
      end
    end
  end
end
