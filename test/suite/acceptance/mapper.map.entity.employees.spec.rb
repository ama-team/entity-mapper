# frozen_string_literal: true

require_relative '../../../lib/mapper'
require_relative '../../../lib/mapper/dsl'
require_relative '../../../lib/mapper/type/any'
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
      let(:employee_photo) do
        factory.call('Employee.Photo') do
          attribute :owner, Integer, nullable: false
          attribute :id, Integer, nullable: false

          denormalizer_block do |input, type, context, &block|
            input = { id: input } if input.is_a?(Integer)
            input[:owner] = context.path.segments[-2].name
            block.call(input, type, context)
          end
        end
      end

      let(:employee) do
        employee_photo_class = employee_photo
        factory.call('Employee') do
          attribute :id, Integer
          attribute :first_name, String
          attribute :last_name, String
          attribute :photo, employee_photo_class, nullable: true
          attribute :department, Integer
          # npc character is intentionally omitted from values list
          attribute :character, Symbol, values: %i[antagonist protagonist], default: :npc

          denormalizer_block do |input, type, context, &block|
            input = { name: input } if input.is_a?(String)
            if input[:name]
              input[:first_name], input[:last_name] = input[:name].split(' ', 2)
            end
            input[:department] = context.path.segments[-3].name
            input[:id] = context.path.segments.last.name
            block.call(input, type, context)
          end
        end
      end

      let(:department) do
        employee_class = employee
        factory.call('Department') do
          attribute :id, Integer
          attribute :name, String
          attribute :profiles, [Set, T: Symbol]
          attribute :employees, [Hash, K: Integer, V: employee_class]

          denormalizer_block do |input, type, context, &block|
            input[:id] = context.path.segments.last.name
            unless input[:profiles].is_a?(Enumerable)
              input[:profiles] = [input[:profiles]]
            end
            block.call(input, type, context)
          end
        end
      end

      describe '> employees & departments' do
        it 'solves case #1' do |test_case|
          input = {
            1 => {
              name: 'Warehouse',
              profiles: 'storage',
              employees: {
                1 => 'John Doe',
                2 => 'Jane Doe'
              }
            },
            2 => {
              name: :Sales,
              profiles: %i[sales],
              employees: {
                3 => {
                  name: 'Johnny Does',
                  photo: 32,
                  character: 'protagonist'
                },
                4 => {
                  name: 'James Moe',
                  photo: {
                    id: 33
                  },
                  character: :antagonist
                }
              }
            }
          }

          type = [Hash, K: Integer, V: department]
          structure1 = nil
          normalization1 = nil
          structure2 = nil
          normalization2 = nil
          test_case.step 'data-to-class mapping #1' do
            structure1 = klass.map(input, type, logger: logger)
          end
          test_case.step 'data validation' do
            expect(structure1[2].id).to eq(2)
            expect(structure1[2].name).to eq('Sales')
            expect(structure1[2].profiles).to eq(Set.new(%i[sales]))
            expect(structure1[2].employees[3]).to be_a(employee)
            expect(structure1[2].employees[3].id).to eq(3)
            expect(structure1[2].employees[3].photo.id).to eq(32)
            expect(structure1[2].employees[3].character).to eq(:protagonist)
          end
          test_case.step 'class-to-data normalization #1' do
            normalization1 = klass.normalize(structure1, logger: logger)
            test_case.attach_yaml(normalization1, 'normalization-1')
          end
          test_case.step 'data-to-class mapping #2' do
            structure2 = klass.map(input, type, logger: logger)
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
