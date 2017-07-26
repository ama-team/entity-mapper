# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

require_relative '../type'
require_relative '../mixin/errors'
require_relative '../mixin/reflection'
require_relative 'attribute'
require_relative 'parameter'
require_relative '../api/wrapper/normalizer'
require_relative '../api/wrapper/denormalizer'
require_relative '../api/wrapper/enumerator'
require_relative '../api/wrapper/injector'
require_relative '../api/wrapper/factory'
require_relative '../api/default/normalizer'
require_relative '../api/default/denormalizer'
require_relative '../api/default/enumerator'
require_relative '../api/default/injector'
require_relative '../api/default/factory'

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
          # Normalizer proc that can be used to convert existing entity into
          # basic data structure (Hash, String, or however entity should be
          # represented).
          #
          # This proc may use passed block to invoke standard normalization
          # operation on passed data, allowing fallback, pre- or post-editing.
          #
          # Arguments: input, context, target type, fallback-block
          #
          # @!attribute normalizer
          #   @return [AMA::Entity::Mapper::API::Normalizer]
          attr_accessor :normalizer
          # Denormalizer proc that can be used to convert basic data structure
          # into entity.
          #
          # This proc may use passed block to invoke standard normalization
          # operation on passed data, allowing fallback, pre- or post-editing.
          #
          # Arguments: input, context, target type, fallback-block
          #
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

          def initialize(klass)
            @type = validate_type!(klass)
            @parameters = {}
            @attributes = {}
            %i[factory normalizer denormalizer enumerator injector].each do |h|
              send("#{h}=", API::Default.const_get(h.capitalize)::INSTANCE)
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
          def satisfied_by?(object)
            return false unless instance?(object)
            enumerator.enumerate(object, self).all? do |attribute, value, *|
              attribute.satisfied_by?(value)
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
          # @return [AMA::Entity::Mapper::Type::Parameter]
          def parameter!(id)
            id = id.to_sym
            return parameters[id] if parameters.key?(id)
            parameters[id] = Parameter.new(self, id)
          end

          # Resolves single parameter type
          #
          # @param [AMA::Entity::Mapper::Type::Parameter] parameter
          # @param [AMA::Entity::Mapper::Type] substitution
          def resolve_parameter(parameter, substitution, context = nil)
            parameter = normalize_parameter(parameter, context)
            substitution = normalize_substitution(substitution, context)
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

          def hash
            @type.hash
          end

          def eql?(other)
            return false unless other.is_a?(self.class)
            @type == other.type
          end

          def to_s
            representation = @type.to_s
            return representation if parameters.empty?
            params = parameters.map do |key, value|
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

          def normalize_parameter(parameter, context = nil)
            if parameter.is_a?(Symbol) && parameters.key?(parameter)
              return parameters[parameter]
            end
            return parameter if parameter.is_a?(Parameter)
            message = "Non-parameter type #{parameter} " \
              'supplied for resolution'
            compliance_error(message, context: context)
          end

          def normalize_substitution(substitution, context)
            return substitution if substitution.is_a?(Type)
            if [Module, Class].any? { |type| substitution.is_a?(type) }
              return Concrete.new(substitution)
            end
            message = "#{substitution.class} is passed as parameter " \
              'substitution, Type / Class / Module expected'
            compliance_error(message, context: context)
          end
        end
      end
    end
  end
end
