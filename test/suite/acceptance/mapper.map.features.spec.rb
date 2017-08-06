# frozen_string_literal: true

require_relative '../../../lib/ama-entity-mapper'
require_relative '../../../lib/ama-entity-mapper/dsl'

klass = ::AMA::Entity::Mapper
dsl_class = ::AMA::Entity::Mapper::DSL

describe klass do
  let(:sensitive) do
    Class.new do
      include dsl_class

      attribute :sensitive, sensitive: true
    end
  end

  describe '> features' do
    describe '> context.include_sensitive_attributes' do
      it 'includes sensitive attributes if set' do
        subject = sensitive.new
        subject.sensitive = 12
        raw = klass.normalize(subject, include_sensitive_attributes: true)
        expect(raw).to be_a(Hash)
        expect(raw).to include(:sensitive)
        expect(raw[:sensitive]).to eq(subject.sensitive)
      end
    end
  end
end
