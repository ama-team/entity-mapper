# frozen_string_literal: true

require_relative '../mixin/reflection'
require_relative '../handler/entity/factory'
require_relative '../handler/entity/enumerator'
require_relative '../handler/entity/injector'
require_relative '../handler/entity/normalizer'
require_relative '../handler/entity/denormalizer'
require_relative '../handler/entity/validator'
require_relative '../type'
require_relative '../type/any'
require_relative '../type/parameter'

module AMA
  module Entity
    class Mapper
      module DSL
        # Module providing DSL methods for entity class
        module ClassMethods
          include Mixin::Reflection

          attr_reader :engine

          def engine=(engine)
            @engine = engine
            engine.register(self)
          end

          # @return [AMA::Entity::Mapper::Type]
          def bound_type
            @engine[self]
          end

          # @param [String, Symbol] name
          # @param [Array<AMA::Entity::Mapper::Type] types List of possible
          #   attribute types
          # @param [Hash] options Attribute options:
          # @option options [TrueClass, FalseClass] virtual
          # @option options [TrueClass, FalseClass] sensitive
          # @option options [TrueClass, FalseClass] nullable
          # @option options [Object] default
          # @option options [Array] values
          # @return [AMA::Entity::Mapper::Type::Attribute]
          def attribute(name, *types, **options)
            types = types.map do |type|
              next parameter(type) if type.is_a?(Symbol) || type.is_a?(String)
              next type if type.is_a?(Type::Parameter)
              @engine.resolve(type)
            end
            types = [Type::Any::INSTANCE] if types.empty?
            bound_type.attribute!(name, *types, **options)
            define_method(name) do
              instance_variable_get("@#{name}")
            end
            define_method("#{name}=") do |value|
              instance_variable_set("@#{name}", value)
            end
          end

          # Returns parameter reference
          #
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
            denormalizer: :denormalize,
            validator: :validate
          }
          handlers.each do |name, method_name|
            setter_name = "#{name}="
            define_method setter_name do |handler|
              wrapper = Handler::Entity.const_get(name.capitalize).wrap(handler)
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
