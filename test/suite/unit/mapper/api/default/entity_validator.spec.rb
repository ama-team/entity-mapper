# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/api/default/entity_validator'

klass = ::AMA::Entity::Mapper::API::Default::EntityValidator

describe klass do
  let(:attributes) do
    intermediate = %i[alpha beta].map do |name|
      attribute = double(
        validator: double(validate: [])
      )
      [name, attribute]
    end
    Hash[intermediate]
  end

  let(:type) do
    double(
      type: nil,
      attributes: attributes,
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

  describe '#validate' do
    it 'just aggregates attribute validators output' do
      expect(type.enumerator).to(
        receive(:enumerate) do
          ::Enumerator.new do |y|
            attributes.values.each do |attribute|
              y << [attribute, nil, nil]
            end
          end
        end
      )
      data = ['violation']
      attributes.values.each do |attribute|
        expect(attribute.validator).to(
          receive(:validate).exactly(:once).and_return(data)
        )
      end
      expectation = attributes.values.flat_map do |attribute|
        data.map do |violation|
          [attribute, violation, nil]
        end
      end
      expect(validator.validate(double, type, context)).to eq(expectation)
    end
  end
end
