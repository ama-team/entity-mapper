# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/api/default/attribute_validator'
require_relative '../../../../../../lib/mapper/exception/validation_error'

klass = ::AMA::Entity::Mapper::API::Default::AttributeValidator
validation_error_class = ::AMA::Entity::Mapper::Exception::ValidationError

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
      lambda do
        validator.validate!(value, attribute, context)
      end
    end
  end

  describe '#validate!' do
    it 'accepts nil if attribute is nullable' do
      allow(attribute).to receive(:nullable).and_return(true)
      expect(&factory.call(nil)).not_to raise_error
    end

    it 'raises if attribute is not nullable but nil is received' do
      expect(&factory.call(nil)).to raise_error(validation_error_class)
    end

    it 'raises if value is not instance of any type' do
      allow(attribute.types.first).to receive(:instance?).and_return(false)
      expect(&factory.call(:anything)).to raise_error(validation_error_class)
    end

    it 'accepts value if it is listed in acceptable values' do
      allow(attribute).to receive(:values).and_return(%i[acceptable])
      expect(&factory.call(:acceptable)).not_to raise_error
    end

    it 'raises if value is not listed in acceptable values' do
      allow(attribute).to receive(:values).and_return(%i[acceptable])
      expect(&factory.call(:rejectable)).to raise_error(validation_error_class)
    end

    it 'accepts value if it is specified as default value' do
      allow(attribute).to receive(:default).and_return(:default)
      expect(&factory.call(:default)).not_to raise_error
    end
  end
end
