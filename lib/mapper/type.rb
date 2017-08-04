# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

require_relative 'mixin/errors'
require_relative 'mixin/reflection'
require_relative 'mixin/handler_support'
require_relative 'context'
require_relative 'type/parameter'
require_relative 'type/attribute'
require_relative 'handler/entity/normalizer'
require_relative 'handler/entity/denormalizer'
require_relative 'handler/entity/enumerator'
require_relative 'handler/entity/injector'
require_relative 'handler/entity/factory'
require_relative 'handler/entity/validator'

module AMA
  module Entity
    class Mapper
      # Type wrapper
      class Type
        include Mixin::Errors
        include Mixin::Reflection
        include Mixin::HandlerSupport

        # @!attribute type
        #   @return [Class]
        attr_accessor :type
        # @!attribute parameters
        #   @return [Hash{Symbol, AMA::Entity::Mapper::Type::Parameter}]
        attr_accessor :parameters
        # @!attribute attributes
        #   @return [Hash{Symbol, AMA::Entity::Mapper::Type::Attribute}]
        attr_accessor :attributes
        # @!attribute virtual
        #   @return [TrueClass, FalseClass]
        attr_accessor :virtual

        handler_namespace Handler::Entity

        # @!attribute factory
        #   @return [AMA::Entity::Mapper::Handler::Entity::Factory]
        handler :factory, :create
        # @!attribute normalizer
        #   @return [AMA::Entity::Mapper::Handler::Entity::Normalizer]
        handler :normalizer, :normalize
        # @!attribute denormalizer
        #   @return [AMA::Entity::Mapper::Handler::Entity::Denormalizer]
        handler :denormalizer, :denormalize
        # @!attribute enumerator
        #   @return [AMA::Entity::Mapper::Handler::Entity::Enumerator]
        handler :enumerator, :enumerate
        # @!attribute injector
        #   @return [AMA::Entity::Mapper::Handler::Entity::Injector]
        handler :injector, :inject
        # @!attribute injector
        #   @return [AMA::Entity::Mapper::Handler::Entity::Validator]
        handler :validator, :validate

        # @param [Class, Module] klass
        def initialize(klass, virtual: false)
          @type = validate_type!(klass)
          @parameters = {}
          @attributes = {}
          @virtual = virtual
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

        def instance!(object, context)
          return if instance?(object)
          message = "Provided object #{object} is not an instance of #{self}"
          validation_error(message, context: context)
        end

        # @return [TrueClass, FalseClass]
        def resolved?
          attributes.values.all?(&:resolved?)
        end

        # Validates that type is fully resolved, otherwise raises an error
        # @param [AMA::Entity::Mapper::Context] context
        def resolved!(context = Context.new)
          attributes.values.each { |attribute| attribute.resolved!(context) }
        end

        # Shortcut for attribute creation.
        #
        # @param [String, Symbol] name
        # @param [Array<AMA::Entity::Mapper::Type>] types
        # @param [Hash] options
        def attribute!(name, *types, **options)
          name = name.to_sym
          types = types.map do |type|
            next type if type.is_a?(Parameter)
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
          return @parameters[id] if @parameters.key?(id)
          @parameters[id] = Parameter.new(self, id)
        end

        # Resolves single parameter type. Substitution may be either another
        # parameter or array of types.
        #
        # @param [Parameter] parameter
        # @param [Parameter, Array<Type>] substitution
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

        # rubocop:disable Metrics/LineLength

        # @param [Hash<AMA::Entity::Mapper::Type, AMA::Entity::Mapper::Type>] parameters
        # @return [AMA::Entity::Mapper::Type]
        def resolve(parameters)
          parameters.reduce(self) do |carrier, tuple|
            carrier.resolve_parameter(*tuple)
          end
        end

        # rubocop:enable Metrics/LineLength

        def violations(object, context)
          validator.validate(object, self, context)
        end

        def valid?(object, context)
          violations(object, context).empty?
        end

        def valid!(object, context)
          violations = self.violations(object, context)
          return if violations.empty?
          message = "#{object} has failed type #{to_def} validation: " \
            "#{violations.join(', ')}"
          validation_error(message, context: context)
        end

        def hash
          @type.hash ^ @attributes.hash
        end

        def eql?(other)
          return false unless other.is_a?(self.class)
          @type == other.type && @attributes == other.attributes
        end

        def ==(other)
          eql?(other)
        end

        def to_s
          message = "Type #{@type}"
          unless @parameters.empty?
            message += " (parameters: #{@parameters.keys})"
          end
          message
        end

        def to_def
          return @type.to_s if parameters.empty?
          params = parameters.map do |key, value|
            value = [value] unless value.is_a?(Enumerable)
            value = value.map(&:to_def)
            value = value.size > 1 ? "[#{value.join(', ')}]" : value.first
            "#{key}:#{value}"
          end
          "#{@type}<#{params.join(', ')}>"
        end

        private

        def validate_type!(type)
          return type if type.is_a?(Class) || type.is_a?(Module)
          message = 'Expected Type to be instantiated with ' \
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
              'or Array of Types: ' \
              "#{substitution} (#{substitution.class})"
          compliance_error(message)
        end

        def validate_substitutions!(substitutions)
          if substitutions.empty?
            compliance_error('Empty list of substitutions passed')
          end
          invalid = substitutions.reject do |substitution|
            substitution.is_a?(Type)
          end
          return substitutions if invalid.empty?
          compliance_error("Invalid substitutions supplied: #{invalid}")
        end
      end
    end
  end
end
