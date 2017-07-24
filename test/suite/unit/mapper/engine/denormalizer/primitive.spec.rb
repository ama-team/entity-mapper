# frozen_string_literal: true

require_relative '../../../../../../lib/mapper/engine/denormalizer/primitive'
require_relative '../../../../../../lib/mapper/type/concrete'
require_relative '../../../../../../lib/mapper/exception/mapping_error'

klass = ::AMA::Entity::Mapper::Engine::Denormalizer::Primitive
mapping_error_class = ::AMA::Entity::Mapper::Exception::MappingError

describe klass do
  let(:denormalizer) do
    klass.new
  end

  let(:context) do
    nil
  end

  describe '#denormalize' do
    variants = {
      NilClass => nil,
      String => 'string',
      Symbol => { value: :symbol, methods: [:to_sym] },
      TrueClass => { value: true, methods: [:to_bool], illegal_values: [false] },
      FalseClass => { value: false, methods: [:to_bool], illegal_values: [true] },
      Float => { value: 0.1, methods: [:to_f] },
      Integer => { value: 1, methods: [:to_i] },
      Array => { value: [1, 2], methods: [:to_a] },
      Hash => { value: { x: 1 }, methods: [:to_h] }
    }

    variants.each do |value_class, definition|
      definition = { value: definition } unless definition.is_a?(Hash)
      value = definition[:value]
      methods = definition.fetch(:methods, [])
      it "should pass #{value_class} through" do
        type = double(type: value_class)
        expect(denormalizer.denormalize(value, context, type)).to eq(value)
      end

      describe "> #{value_class}" do
        methods.each do |method|
          it "should denormalize value to #{value_class} if it has :#{method} method" do
            subject = double(**{ method => value })
            type = double(type: value_class)
            expect(denormalizer.denormalize(subject, context, type)).to eq(value)
          end

          it "should raise error if :#{method} method returns something other than #{value_class}" do
            subject = double(**{ method => nil })
            type = double(type: value_class)
            proc = lambda do
              denormalizer.denormalize(subject, context, type)
            end
            expect(&proc).to raise_error(mapping_error_class)
          end

          definition.fetch(:illegal_values, []).each do |illegal_value|
            it "should raise error if :#{method} method returns #{illegal_value}" do
              subject = double(**{ method => illegal_value })
              type = double(**{ type: value_class })
              proc = lambda do
                denormalizer.denormalize(subject, context, type)
              end
              expect(&proc).to raise_error(mapping_error_class)
            end
          end
        end

        unless methods.empty?
          it 'should raise mapping error if all supplementary methods require arguments' do
            subject = double
            methods.each do |method|
              allow(subject).to receive(method).and_raise(ArgumentError)
            end
            type = double(type: value_class)
            proc = lambda do
              denormalizer.denormalize(subject, context, type)
            end
            expect(&proc).to raise_error(mapping_error_class)
          end
        end
      end
    end
  end
end
