# frozen_string_literal: true

require_relative '../mixin/reflection'

module AMA
  module Entity
    class Mapper
      module DSL
        # Module providing DSL methods for entity class
        module ClassMethods
          include Mixin::Reflection

          attr_reader :mapper

          def mapper=(mapper)
            @mapper = mapper
            mapper.register(self)
          end

          # @return [AMA::Entity::Mapper::Type::Concrete]
          def bound_type
            mapper[self]
          end

          # @param [String, Symbol] name
          # @param [Array<AMA::Entity::Mapper::Type] types List of possible
          #   attribute types
          # @param [Hash] options Attribute options: :virtual, :sensitive
          # @return [AMA::Entity::Mapper::Type::Attribute]
          def attribute(name, *types, **options)
            types = types.map { |type| @mapper.resolve(type) }
            bound_type.attribute!(name, *types, **options)
            define_method(name) do
              instance_variable_get("@#{name}")
            end
            define_method("#{name}=") do |value|
              instance_variable_set("@#{name}", value)
            end
          end

          # @param [String, Symbol] id
          # @return [AMA::Entity::Mapper::Type::Parameter]
          def parameter(id)
            bound_type.parameter!(id)
          end

          handlers = {
            factory: :create,
            enumerator: :enumerate,
            injector: :inject,
            normalizer: :normalize,
            denormalizer: :denormalize
          }
          handlers.each do |name, method_name|
            setter_name = "#{name}="
            define_method setter_name do |handler|
              wrapper = API::Wrapper.const_get(name.capitalize).new(handler)
              bound_type.send(setter_name, wrapper)
            end

            define_method "#{name}_block" do |&block|
              send(setter_name, method_object(method_name, &block))
            end
          end
        end
      end
    end
  end
end
