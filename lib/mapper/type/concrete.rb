# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

require_relative '../type'
require_relative '../mixin/errors'
require_relative '../mixin/reflection'
require_relative 'attribute'
require_relative 'parameter'
require_relative '../handler/entity/normalizer'
require_relative '../handler/entity/denormalizer'
require_relative '../handler/entity/enumerator'
require_relative '../handler/entity/injector'
require_relative '../handler/entity/factory'
require_relative '../handler/entity/validator'

module AMA
  module Entity
    class Mapper
      class Type
        # Basic type class that describes specific type. Type may have
        # arbitrary number of attributes (regular and virtual) and parameters -
        # types that are known until runtime (this is usually referenced as
        # generics).
        class Concrete < Type
          include Mixin::Errors
          include Mixin::Reflection

          # @!attribute type
          #   @return [Class]
          attr_accessor :type
          # @!attribute parameters
          #   @return [Hash{Symbol, AMA::Entity::Mapper::Type::Parameter}]
          attr_accessor :parameters
          # @!attribute attributes
          #   @return [Hash{Symbol, AMA::Entity::Mapper::Type::Attribute}]
          attr_accessor :attributes
          # @!attribute normalizer
          #   @return [AMA::Entity::Mapper::API::Normalizer]
          attr_accessor :normalizer
          # @!attribute denormalizer
          #   @return [AMA::Entity::Mapper::API::Denormalizer]
          attr_accessor :denormalizer
          # @!attribute enumerator
          #   @return [AMA::Entity::Mapper::API::Enumerator]
          attr_accessor :enumerator
          # @!attribute [w] acceptor
          #   @return [AMA::Entity::Mapper::API::Injector]
          attr_accessor :injector
          # @!attribute factory
          #   @return [AMA::Entity::Mapper::API::Factory]
          attr_accessor :factory
          # @!attribute validator
          #   @return [AMA::Entity::Mapper::API:Validator]
          attr_accessor :validator

          # @param [Class, Module] klass
          def initialize(klass)
            @type = validate_type!(klass)
            @parameters = {}
            @attributes = {}
            handlers = %i[
              factory normalizer denormalizer enumerator injector validator
            ]
            handlers.each do |h|
              send("#{h}=", Handler::Entity.const_get(h.capitalize)::INSTANCE)
            end
          end

          # Tells if provided object is an instance of this type.
          #
          # This doesn't mean all of it's attributes do match requested types.
          #
          # @param [Object] object
          # @return [TrueClass, FalseClass]
          def instance?(object)
            object.is_a?(@type)
          end

          # Tells if provided object fully complies to type spec.
          #
          # @param [Object] object
          # @return [TrueClass, FalseClass]
          def satisfied_by?(object, context)
            return false unless instance?(object)
            enumerator.enumerate(object, self, context).all? do |attr, value, *|
              attr.satisfied_by?(value, context)
            end
          end

          # Shortcut for attribute creation.
          #
          # @param [String, Symbol] name
          # @param [Array<AMA::Entity::Mapper::Type>] types
          # @param [Hash] options
          def attribute!(name, *types, **options)
            types = types.map do |type|
              next parameter!(type) if type.is_a?(Symbol)
              next self.class.new(type) unless type.is_a?(Type)
              type
            end
            attributes[name] = Attribute.new(self, name, *types, **options)
          end

          # Creates new type parameter
          #
          # @param [Symbol] id
          # @return [Parameter]
          def parameter!(id)
            id = id.to_sym
            return parameters[id] if parameters.key?(id)
            parameters[id] = Parameter.new(self, id)
          end

          # Resolves single parameter type. Substitution may be either another
          # parameter, concrete type or array of concrete types.
          #
          # @param [Parameter] parameter
          # @param [Parameter, Array<Concrete>] substitution
          def resolve_parameter(parameter, substitution)
            parameter = validate_parameter!(parameter)
            substitution = validate_substitution!(substitution)
            clone.tap do |clone|
              intermediate = attributes.map do |key, value|
                [key, value.resolve_parameter(parameter, substitution)]
              end
              clone.attributes = Hash[intermediate]
              intermediate = clone.parameters.map do |key, value|
                [key, value == parameter ? substitution : value]
              end
              clone.parameters = Hash[intermediate]
            end
          end

          def violations(object, context)
            validator.validate(object, self, context)
          end

          def factory_block(&block)
            self.factory = method_object(:create, &block)
          end

          def normalizer_block(&block)
            self.normalizer = method_object(:normalize, &block)
          end

          def denormalizer_block(&block)
            self.denormalizer = method_object(:denormalize, &block)
          end

          def enumerator_block(&block)
            self.enumerator = method_object(:enumerate, &block)
          end

          def injector_block(&block)
            self.injector = method_object(:inject, &block)
          end

          def validator_block(&block)
            self.validator = method_object(:validate, &block)
          end

          def hash
            @type.hash ^ @attributes.hash
          end

          def eql?(other)
            return false unless other.is_a?(self.class)
            @type == other.type && @attributes == other.attributes
          end

          def to_s
            representation = @type.to_s
            return representation if parameters.empty?
            params = parameters.map do |key, value|
              if value.is_a?(Enumerable)
                value = "[#{value.map(&:to_s).join(', ')}]"
              end
              value = value.is_a?(Parameter) ? '?' : value.to_s
              "#{key}:#{value}"
            end
            "#{representation}<#{params.join(', ')}>"
          end

          private

          def validate_type!(type)
            return type if type.is_a?(Class) || type.is_a?(Module)
            message = 'Expected concrete type to be instantiated with ' \
              "Class/Module instance, got #{type}"
            compliance_error(message)
          end

          def validate_parameter!(parameter)
            return parameter if parameter.is_a?(Parameter)
            message = "Non-parameter type #{parameter} " \
              'supplied for resolution'
            compliance_error(message)
          end

          def validate_substitution!(substitution)
            return substitution if substitution.is_a?(Parameter)
            substitution = [substitution] if substitution.is_a?(self.class)
            if substitution.is_a?(Enumerable)
              return validate_substitutions!(substitution)
            end
            message = 'Provided substitution is neither another Parameter ' \
              'or Array of concrete Types: ' \
              "#{substitution} (#{substitution.class})"
            compliance_error(message)
          end

          def validate_substitutions!(substitutions)
            if substitutions.empty?
              compliance_error('Empty list of substitutions passed')
            end
            invalid = substitutions.reject do |substitution|
              substitution.is_a?(Concrete)
            end
            return substitutions if invalid.empty?
            compliance_error("Invalid substitutions supplied: #{invalid}")
          end
        end
      end
    end
  end
end
