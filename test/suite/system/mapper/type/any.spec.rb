# frozen_string_literal: true

require_relative '../../../../../lib/mapper/type/any'
require_relative '../../../../../lib/mapper/type/concrete'
require_relative '../../../../../lib/mapper/type/parameter'

klass = ::AMA::Entity::Mapper::Type::Any
concrete_type_klass = ::AMA::Entity::Mapper::Type::Concrete
parameter_type_klass = ::AMA::Entity::Mapper::Type::Parameter

describe klass do
  let(:concrete) do
    concrete_type_klass.new(Class.new)
  end

  let(:parameter) do
    parameter_type_klass.new(concrete, :T)
  end

  describe '#eql?' do
    it 'should be equal to concrete type' do
      expect(klass::INSTANCE).to eq(concrete)
    end

    it 'should be equal to parameter type' do
      expect(klass::INSTANCE).to eq(parameter)
    end
  end
end
