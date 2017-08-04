# frozen_string_literal: true

require_relative '../../../lib/mapper'
require_relative '../../../lib/mapper/dsl'
require_relative '../../../lib/mapper/type/any'
require_relative '../../../lib/mapper/context'
require_relative '../../../lib/mapper/error/mapping_error'

klass = ::AMA::Entity::Mapper
dsl_class = ::AMA::Entity::Mapper::DSL
any_type = ::AMA::Entity::Mapper::Type::Any::INSTANCE
mapping_error_class = ::AMA::Entity::Mapper::Error::MappingError

describe klass do
  describe '#map' do
    describe '> primitives' do
      let(:container) do
        Class.new do
          include dsl_class

          attr_accessor :value

          denormalizer_block do |value, *|
            new(value)
          end

          normalizer_block do |entity, *|
            entity.value
          end

          def initialize(value = nil)
            @value = value
          end

          def to_s
            "Container<#{@value}>"
          end

          def self.to_s
            'Container'
          end
        end
      end

      variants = {
        nil => [],
        1 => %i[to_i],
        1.00 => %i[to_f],
        true => %i[to_bool to_b],
        false => %i[to_bool to_b],
        :symbol => %i[to_sym],
        'string' => []
      }

      variants.each do |variant, methods|
        describe "> #{variant.class}" do
          it 'passed through if corresponding type is provided' do
            type = variant.class
            expect(klass.map(variant, type, logger: logger)).to equal(variant)
          end

          unless variant.nil?
            it 'passed through if Any type is provided' do
              result = klass.map(variant, any_type, logger: logger)
              expect(result).to equal(variant)
            end
          end

          it 'raises if no helper methods are provided on unknown type' do
            proc = lambda do
              klass.map(double, variant.class, logger: logger)
            end
            expect(&proc).to raise_error(mapping_error_class)
          end

          methods.each do |method|
            it "extracted using #{method} if it is present" do
              type = variant.class
              source = container.new(variant)
              expect(klass.map(source, type, logger: logger)).to eq(variant)
            end

            it "fails extraction if #{method} returns unexpected data" do
              proc = lambda do
                klass.map(container.new(double), variant.class, logger: logger)
              end
              expect(&proc).to raise_error(mapping_error_class)
            end
          end
        end
      end
    end
  end
end
