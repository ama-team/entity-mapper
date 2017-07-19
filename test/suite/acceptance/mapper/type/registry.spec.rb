# frozen_string_literal: true

require_relative '../../../../../lib/mapper/type/registry'
require_relative '../../../../../lib/mapper/type/concrete'

klass = ::AMA::Entity::Mapper::Type::Registry
type_class = ::AMA::Entity::Mapper::Type::Concrete

describe klass do
  let(:registry) do
    klass.new
  end

  describe '#find' do
    it 'should find Hash type for Hash rather than Enumerable' do
      hash_type = type_class.new(Hash)
      enumerable_type = type_class.new(Enumerable)
      types = [hash_type, enumerable_type]

      [types, types.reverse].each do |type_collection|
        registry = klass.new
        type_collection.each do |type|
          registry.register(type)
        end
        expect(registry.find(Hash)).to eq(hash_type)
      end
    end
  end
end
