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
      type: double(is_a?: false),
      values: [:value]
    )
  end

  let(:context) do
    double(
      path: double(
        current: nil
      )
    )
  end

  describe '#validate!' do
    it 'accepts nil if attribute is nullable' do
      allow(attribute).to receive(:nullable).and_return(true)
      proc = lambda do
        validator.validate!(nil, attribute, context)
      end
      expect(&proc).not_to raise_error
    end

    it 'raises if attribute is not nullable but nil is received' do
      proc = lambda do
        validator.validate!(nil, attribute, context)
      end
      expect(&proc).to raise_error(validation_error_class)
    end
  end
end
