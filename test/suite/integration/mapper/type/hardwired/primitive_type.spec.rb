# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/type/hardwired/primitive_type'
require_relative '../../../../../../lib/mapper/error/compliance_error'

klass = ::AMA::Entity::Mapper::Type::Hardwired::PrimitiveType
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError

describe klass do
  let(:context) do
    context = double(path: double(current: nil))
    allow(context).to receive(:advance).and_return(context)
    context
  end

  describe '> common' do
    klass::ALL.each do |type|
      describe type.type do
        describe '#factory' do
          it 'restricts calls' do
            proc = lambda do
              type.factory.create(type, double, context)
            end
            expect(&proc).to raise_error(compliance_error_class)
          end
        end

        describe '#enumerator' do
          it 'returns empty enumerator' do
            proc = lambda do |listener|
              type.enumerator.enumerate(double, type, context).each(&listener)
            end
            expect(&proc).not_to yield_control
          end
        end

        describe '#injector' do
          it 'returns noop injector' do
            type.injector.inject(nil, type, double, nil, context)
          end
        end
      end
    end
  end
end
