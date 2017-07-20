# frozen_string_literal: true

require_relative '../type'
require_relative '../mixin/errors'
require_relative 'attribute'
require_relative 'parameter'

module AMA
  module Entity
    class Mapper
      class Type
        # Used to describe concrete type (that means, class is already known,
        # though it's parameters may be resolved later).
        class Concrete < Type
          include Mixin::Errors

          # @!attribute type
          #   @return [Class]
          attr_accessor :type
          # @!attribute parameters
          #   @return [Hash{Symbol, AMA::Entity::Mapper::Type}]
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
          # @!attribute validator Ruby block that validates result
          #   @return [Proc]
          attr_accessor :validator
          # @!attribute factory
          #   @return [Proc]
          attr_accessor :factory
          # A special processor that takes in existing object instance, then
          # uses passed block to process them and reconstructs new instance -
          # this is used to traverse objects without direct traversal:
          #
          # mapper = lambda do |instance, context = nil, &block|
          #   copy = instance.clone
          #   attributes.values.each do |attribute|
          #     value = attribute.extract(instance)
          #     attribute.set(copy, block.call(attribute, value))
          #   end
          # end
          #
          # Or to traverse hash as it would be regular type:
          #
          # mapper = lambda do |instance, context = nil, &block|
          #   copy = {}
          #   instance.each do |key, val|
          #     key = block.call(attributes[:_key], key, Segment.index(key))
          #     val = block.call(attributes[:_val], val, Segment.index(key))
          #     copy[key] = val
          #   end
          #   copy
          # end
          #
          # @!attribute mapper
          #   @return [Proc]
          attr_accessor :mapper

          def initialize(type)
            @type = validate_type!(type)
            @parameters = {}
            @attributes = {}
          end

          def instance?(object)
            object.is_a?(@type)
          end

          def satisfied_by?(object)
            return false unless instance?(object)
            attributes.values.each do |attribute|
              value = attribute.extract(object)
              return false unless attribute.satisfied_by?(value)
            end
            true
          end

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

          def instantiate(context = nil, data = nil)
            return invoke_factory(context, data) if factory
            invoke_constructor(context)
          end

          # @param [Object] object
          # @param [AMA::Entity::Mapper::Context] context
          def map(object, context = nil, &block)
            return @mapper.call(object, context, &block) if @mapper
            copy = instantiate(context, object)
            @attributes.values.each do |attribute|
              value = attribute.extract(object)
              attribute.set(copy, yield(attribute, value))
            end
            copy
          end

          def resolve_parameter(parameter, substitution)
            clone.tap do |clone|
              intermediate = attributes.map do |key, value|
                [key, value.resolve_parameter(parameter, substitution)]
              end
              clone.attributes = Hash[intermediate]
            end
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

          def invoke_factory(context = nil, data = nil)
            factory.call(context, data) if factory
          rescue StandardError => e
            message = "Failed to instantiate type #{self} using factory"
            mapping_error(message, parent: e, context: context)
          end

          def invoke_constructor(context = nil)
            @type.new
          rescue StandardError => e
            message = "Failed to instantiate type #{self} from class, " \
              'is it\'s #initialize() parameterless?'
            mapping_error(message, parent: e, context: context)
          end

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
