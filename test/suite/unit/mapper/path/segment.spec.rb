# frozen_string_literal: true

require_relative '../../../../../lib/mapper/path/segment'

klass = ::AMA::Entity::Mapper::Path::Segment

describe klass do
  describe '#hash' do
    variants = [
      %w[alpha],
      %w[alpha #],
      %w[alpha \[ \]]
    ]
    variants.each do |variant|
      it "should produce equal hashes for equal instances created from #{variant}" do
        expect(klass.new(*variant).hash).to eq(klass.new(*variant).hash)
      end
    end
  end
end
