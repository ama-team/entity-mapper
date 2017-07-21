# frozen_string_literal: true

require_relative '../type'
require_relative '../mixin/errors'
require_relative 'attribute'
require_relative 'parameter'
require_relative 'concrete/factory'
require_relative 'concrete/enumerator'
require_relative 'concrete/acceptor'
require_relative 'concrete/wrappers'

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
          #   @return [Proc]
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
          #   @return [Proc]
          attr_accessor :denormalizer
          # @!attribute enumerator
          #   @return [Proc]
          attr_reader :enumerator
          # @!attribute acceptor
          #   @return [Proc]
          attr_reader :acceptor
          # @!attribute factory
          #   @return [Proc]
          attr_reader :factory

          def initialize(type)
            @type = validate_type!(type)
            @parameters = {}
            @attributes = {}
            self.factory = Factory.new(self)
            self.enumerator = ->(object, *) { Enumerator.new(self, object) }
            self.acceptor = ->(object, *) { Acceptor.new(self, object) }
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
            enumerator(object).all? do |attribute, value, *|
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
          def resolve_parameter(parameter, substitution)
            unless parameter.is_a?(Parameter)
              message = "Non-parameter type #{parameter} " \
                'supplied for resolution'
              mapping_error(message, nil)
            end
            clone.tap do |clone|
              intermediate = attributes.map do |key, value|
                [key, value.resolve_parameter(parameter, substitution)]
              end
              clone.attributes = Hash[intermediate]
              clone.parameters = clone.parameters.reject do |_, p|
                p == parameter
              end
            end
          end

          def factory=(factory)
            @factory = Wrappers.factory(self, factory)
          end

          def enumerator(object, context = nil)
            @enumerator.call(object, context)
          end

          def enumerator=(enumerator_factory)
            @enumerator = Wrappers.enumerator(self, enumerator_factory)
          end

          def acceptor(object, context = nil)
            @acceptor.call(object, context)
          end

          def acceptor=(acceptor_factory)
            @acceptor = Wrappers.acceptor(self, acceptor_factory)
          end

          def hash
            @type.hash
          end

          def eql?(other)
            return false unless other.is_a?(self.class)
            @type == other.type
          end

          def to_s
            "Concrete Type {#{@type}}"
          end

          private

          def validate_type!(type)
            return type if type.is_a?(Class) || type.is_a?(Module)
            message = 'Expected concrete type to be instantiated with ' \
              "Class/Module instance, got #{type}"
            compliance_error(message, nil)
          end
        end
      end
    end
  end
end
