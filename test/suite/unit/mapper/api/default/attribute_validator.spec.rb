# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/api/default/attribute_validator'
require_relative '../../../../../../lib/mapper/exception/validation_error'

klass = ::AMA::Entity::Mapper::API::Default::AttributeValidator

describe klass do
  let(:validator) do
    klass::INSTANCE
  end

  let(:attribute) do
    double(
      default: nil,
      nullable: false,
      types: [double(instance?: true)],
      values: []
    )
  end

  let(:context) do
    double(
      path: double(
        current: nil
      )
    )
  end

  let(:factory) do
    lambda do |value|
      validator.validate(value, attribute, context)
    end
  end

  describe '#validate' do
    it 'accepts nil if attribute is nullable' do
      allow(attribute).to receive(:nullable).and_return(true)
      expect(factory.call(nil)).to eq([])
    end

    it 'reports violation if attribute is not nullable but nil is received' do
      expect(factory.call(nil)).not_to be_empty
    end

    it 'reports violation if value is not an instance of any type' do
      allow(attribute.types.first).to receive(:instance?).and_return(false)
      expect(factory.call(:anything)).not_to be_empty
    end

    it 'accepts value if it is listed in acceptable values' do
      allow(attribute).to receive(:values).and_return(%i[acceptable])
      expect(factory.call(:acceptable)).to be_empty
    end

    it 'reports violation if value is not listed in acceptable values' do
      allow(attribute).to receive(:values).and_return(%i[acceptable])
      expect(factory.call(:rejectable)).not_to be_empty
    end

    it 'accepts value if it is specified as default value' do
      allow(attribute).to receive(:default).and_return(:default)
      expect(factory.call(:default)).to be_empty
    end
  end
end
