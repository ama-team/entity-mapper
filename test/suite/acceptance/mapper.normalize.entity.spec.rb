# frozen_string_literal: true

require_relative '../../../lib/ama-entity-mapper'
require_relative '../../../lib/ama-entity-mapper/dsl'
require_relative '../../../lib/ama-entity-mapper/type/any'

klass = ::AMA::Entity::Mapper
dsl_klass = ::AMA::Entity::Mapper::DSL
any_type = ::AMA::Entity::Mapper::Type::Any

factory = lambda do |name, &block|
  Class.new do
    include dsl_klass
    define_singleton_method :to_s do
      name
    end
    class_eval(&block)
  end
end

describe klass do
  describe '#normalize' do
    describe '> entity' do
      let(:simple) do
        factory.call('SimpleEntity') do
          attribute :id, Symbol
          attribute :value, any_type, nullable: true

          def initialize(id = nil, value = nil)
            @id = id
            @value = value
          end
        end
      end

      let(:sensitive) do
        factory.call('SensitiveEntity') do
          attribute :sensitive, any_type, sensitive: true

          def initialize(sensitive = nil)
            @sensitive = sensitive
          end
        end
      end

      it 'normalizes simple entity to hash' do
        entity = simple.new(:bill, 'vietnam horseshit')
        expectation = {
          id: entity.id,
          value: entity.value
        }
        expect(klass.normalize(entity, logger: logger)).to eq(expectation)
      end

      it 'normalizes nested entity to nested hash' do
        leaf = simple.new(:bill, 'vietnam horseshit')
        root = simple.new(:survivors, leaf)
        expectation = {
          id: root.id,
          value: {
            id: leaf.id,
            value: leaf.value
          }
        }
        expect(klass.normalize(root, logger: logger)).to eq(expectation)
      end

      it 'doesn\'t normalize sensitive attributes' do
        entity = sensitive.new('pa$$word')
        result = klass.normalize(entity, logger: logger)
        expect(result).to be_a(Hash)
        expect(result).not_to include(:sensitive)
      end
    end
  end
end
