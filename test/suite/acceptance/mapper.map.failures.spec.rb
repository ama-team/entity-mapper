# frozen_string_literal: true

require_relative '../../../lib/mapper'
require_relative '../../../lib/mapper/type/any'
require_relative '../../../lib/mapper/error/mapping_error'
require_relative '../../../lib/mapper/error/compliance_error'

klass = ::AMA::Entity::Mapper
compliance_error_class = ::AMA::Entity::Mapper::Error::ComplianceError
mapping_error_class = ::AMA::Entity::Mapper::Error::MappingError
any_type = ::AMA::Entity::Mapper::Type::Any::INSTANCE

describe klass do
  describe '#map' do
    describe '> Failures' do
      it 'raises if unresolved type is passed' do
        proc = lambda do
          klass.map([], [Array, T: Hash], logger: logger)
        end
        expect(&proc).to raise_error(compliance_error_class)
      end

      it 'raises if type can\'t be resolved' do
        proc = lambda do
          klass.map({}, [Array, T: any_type], logger: logger)
        end
        expect(&proc).to raise_error(mapping_error_class)
      end

      it 'fails to map string to integer' do
        proc = lambda do
          klass.map('test', Integer, logger: logger)
        end
        expect(&proc).to raise_error(mapping_error_class)
      end
    end
  end
end
