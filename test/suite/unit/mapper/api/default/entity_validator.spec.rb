# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/api/default/entity_validator'

klass = ::AMA::Entity::Mapper::API::Default::EntityValidator

describe klass do
  let(:attribute) do
    double(
      validator: double(validate!: nil)
    )
  end

  let(:type) do
    double(
      type: nil,
      attributes: {
        id: attribute
      },
      enumerator: double(enumerate: nil)
    )
  end

  let(:validator) do
    klass::INSTANCE
  end

  let(:context) do
    double(
      advance: nil,
      path: double(
        current: double(name: nil)
      )
    )
  end

  describe '#validate!' do
    it 'just passes all the work to enumerator and attribute validators' do
      enumerator = ::Enumerator.new do |y|
        y << [attribute, nil, context]
      end
      expect(type.enumerator).to(
        receive(:enumerate).and_return(enumerator).exactly(:once)
      )
      expect(attribute.validator).to receive(:validate!).exactly(:once)
      validator.validate!(double, type, context)
    end
  end
end
