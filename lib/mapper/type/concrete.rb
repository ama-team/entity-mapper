# frozen_string_literal: true

require_relative '../type'
require_relative '../exception/compliance_error'
require_relative 'attribute'
require_relative 'parameter'
require_relative 'variable'

module AMA
  module Entity
    class Mapper
      class Type
        # Used to describe concrete type (that means, class is already known,
        # though it's parameters may be resolved later).
        class Concrete < Type
          # @!attribute type
          #   @return [Class]
          attr_accessor :type
          # @!attribute parameters
          #   @return [Hash{Symbol, AMA::Entity::Mapper::Type::Proxy}]
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
          # Arguments: input, fallback-block
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
          # Arguments: input, fallback-block
          #
          # @!attribute denormalizer
          #   @return [Proc]
          attr_accessor :denormalizer
          # @!attribute validator Ruby block that validates result
          #   @return [Proc]
          attr_accessor :validator

          def initialize(type)
            unless type.is_a?(Class) || type.is_a?(Module)
              message = 'Expected concrete type to be instantiated with ' \
                "Class/Module instance, got #{type}"
              compliance_error(message)
            end
            @type = type
            @parameters = {}
            @attributes = {}
          end

          def supports_parameters?
            true
          end

          def supports_attributes?
            true
          end

          def attribute(name, *types, **options)
            types = types.map do |type|
              next parameter(type) if type.is_a?(Symbol)
              next self.class.new(type) unless type.is_a?(Type)
              type
            end
            attributes[name] = Attribute.new(self, name, *types, **options)
          end

          def variable(id)
            return parameters[id] if parameters.key?(id)
            parameters[id] = Variable.new(self, id)
          end

          def parameter(id)
            variable(id)
            Parameter.new(self, id)
          end

          def hash
            @type.hash ^ @parameters.hash ^ @attributes.hash
          end

          def eql?(other)
            return false unless other.is_a?(self.class)
            @type == other.type
          end

          def to_s
            "Concrete Type {#{@type}}"
          end

          def clone
            self.class.new(@type).tap do |instance|
              @parameters.each do |id, parameter|
                instance.parameters[id] = parameter.clone
              end
              @attributes.each do |id, attribute|
                instance.attributes[id] = attribute.clone
              end
            end
          end
        end
      end
    end
  end
end
