# frozen_string_literal: true

require_relative '../../../lib/mapper'
require_relative '../../../lib/mapper/dsl'
require_relative '../../../lib/mapper/mixin/reflection'

klass = ::AMA::Entity::Mapper

factory = lambda do |name, &block|
  Class.new do
    include ::AMA::Entity::Mapper::DSL
    include ::AMA::Entity::Mapper::Mixin::Reflection

    class_eval(&block) if block

    define_singleton_method :to_s do
      name
    end

    def eql?(other)
      return false unless other.is_a?(self.class)
      object_variables(self) == object_variables(other)
    end

    def ==(other)
      eql?(other)
    end
  end
end

describe klass do
  describe '#map' do
    describe '> entity' do
      let(:public_key) do
        factory.call('PublicKey') do
          attribute :id, Symbol
          attribute :owner, Symbol
          attribute :content, String, sensitive: true
          attribute :digest, Integer, NilClass, nullable: true
          attribute :type, Symbol, values: %i[ssh-rsa ssh-dss], default: :'ssh-rsa'
          attribute :comment, Symbol, NilClass

          def content=(content)
            @content = content
            @digest = content.size
          end

          denormalizer_block do |input, type, context, &block|
            input = { content: input } if input.is_a?(String)
            %i[id owner].each_with_index do |key, index|
              candidate = context.path.segments[(-1 - index)]
              input[key] = candidate.name if !input[key] && candidate
            end
            block.call(input, type, context)
          end
        end
      end

      let(:container) do
        factory.call('Container') do
          attribute :value, parameter(:T)
        end
      end

      describe '> parametrized entities fiddling' do
        it 'solves case #1' do |test_case|
          types = [
            [container, T: Symbol],
            [container, T: [container, T: Symbol]],
            [container, T: [Hash, K: Symbol, V: [container, T: Symbol]]]
          ]
          type = [Array, T: types]
          input = [
            { value: 'test' },
            { value: { value: 'test' } },
            { value: { value: { value: 'test' } } }
          ]
          structure1 = nil
          structure2 = nil
          normalization1 = nil
          normalization2 = nil
          test_case.step 'data-to-class mapping #1' do
            structure1 = klass.map(input, type, logger: logger)
          end
          test_case.step 'mapping validation: $ is Array{3}' do
            expect(structure1).to be_a(Array)
            expect(structure1.size).to eq(3)
          end
          test_case.step 'mapping validation: $[0] is Container<:test>' do
            expect(structure1.first).to be_a(container)
            expect(structure1.first.value).to eq :test
          end
          test_case.step 'mapping validation: $[1] is Container<Container<:test>' do
            expect(structure1[1]).to be_a(container)
            expect(structure1[1].value).to be_a(container)
            expect(structure1[1].value.value).to eq :test
          end
          test_case.step 'mapping validation: $[2] is Container<Hash<Symbol, Container<:test>>' do
            expect(structure1[2]).to be_a(container)
            expect(structure1[2].value).to be_a(Hash)
            expect(structure1[2].value).to include(:value)
            expect(structure1[2].value[:value]).to be_a(container)
            expect(structure1[2].value[:value].value).to eq :test
          end
          test_case.step 'class-to-data normalization #1' do
            normalization1 = klass.normalize(structure1, logger: logger)
            test_case.attach_yaml(normalization1, 'normalization-1')
          end
          test_case.step 'data-to-class mapping #2' do
            structure2 = klass.map(normalization1, type, logger: logger)
          end
          test_case.step 'class-to-data normalization #2' do
            normalization2 = klass.normalize(structure2, logger: logger)
            test_case.attach_yaml(normalization2, 'normalization-2')
          end

          test_case.step 'equality check' do
            expect(structure1).to eq(structure2)
            expect(normalization1).to eq(normalization2)
          end
        end
      end
    end
  end
end
