# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

require_relative '../handler/attribute/validator'
require_relative '../mixin/errors'
require_relative '../mixin/handler_support'
require_relative 'parameter'

module AMA
  module Entity
    class Mapper
      class Type
        # Stores data about single type attribute
        class Attribute
          include Mixin::Errors
          include Mixin::HandlerSupport

          # @!attribute
          #   @return [AMA::Entity::Mapper::Type]
          attr_accessor :owner
          # @!attribute
          #   @return [Symbol]
          attr_accessor :name
          # @!attribute types List of possible types attribute may take
          #   @return [Array<AMA::Entity::Mapper::Type>]
          attr_accessor :types
          # If attribute is declared as virtual, it is omitted from all
          # automatic actions, such enumeration, normalization and
          # denormalization. Main motivation behind virtual attributes was
          # collections problem: collection can't be represented as hash of
          # attributes, however, virtual attribute may describe collection
          # content.
          #
          # @!attribute virtual
          #   @return [TrueClass, FalseClass]
          attr_accessor :virtual
          # If set to true, this attribute will be omitted during normalization
          # and won't be present in resulting structure.
          #
          # @!attribute sensitive
          #   @return [TrueClass, FalseClass]
          attr_accessor :sensitive
          # Default value that is set on automatic object creation.
          #
          # @!attribute default
          #   @return [Object]
          attr_accessor :default
          # Whether or not this attribute may be represented by null.
          #
          # @!attribute nullable
          #   @return [TrueClass, FalseClass]
          attr_accessor :nullable
          # List of values this attribute acceptable to take. Part of automatic
          # validation.
          #
          # @!attribute values
          #   @return [Array<Object>]
          attr_accessor :values
          # @!attribute aliases
          #   @return [Array<Symbol>]
          attr_accessor :aliases

          handler_namespace Handler::Attribute

          # Custom attribute validator
          #
          # @!attribute validator
          #   @return [API::AttributeValidator]
          handler :validator, :validate

          def self.defaults
            {
              virtual: false,
              sensitive: false,
              default: nil,
              nullable: false,
              values: [],
              validator: nil,
              aliases: []
            }
          end

          # @param [Mapper::Type] owner
          # @param [Symbol] name
          # @param [Array<Mapper::Type>] types
          # @param [Hash<Symbol, Object] options
          def initialize(owner, name, *types, **options)
            @owner = validate_owner!(owner)
            @name = validate_name!(name)
            @types = validate_types!(types)
            self.class.defaults.each do |key, value|
              value = options.fetch(key, value)
              send("#{key}=", options.fetch(key, value)) unless value.nil?
            end
          end

          def violations(value, context)
            validator.validate(value, self, context)
          end

          def valid?(value, context)
            violations(value, context).empty?
          end

          def valid!(value, context)
            violations = self.violations(value, context)
            return if violations.empty?
            repr = violations.join(', ')
            message = "Attribute #{self} has failed validation: #{repr}"
            validation_error(message, context: context)
          end

          def resolved?
            types.all?(&:resolved?)
          end

          def resolved!(context = nil)
            types.each { |type| type.resolved!(context) }
          end

          # @param [AMA::Entity::Mapper::Type] parameter
          # @param [AMA::Entity::Mapper::Type] substitution
          # @return [AMA::Entity::Mapper::Type::Attribute]
          def resolve_parameter(parameter, substitution)
            clone.tap do |clone|
              clone.types = types.each_with_object([]) do |type, carrier|
                if type == parameter
                  buffer = substitution
                  buffer = [buffer] unless buffer.is_a?(Enumerable)
                  next carrier.push(*buffer)
                end
                carrier.push(type.resolve_parameter(parameter, substitution))
              end
            end
          end

          def hash
            @owner.hash ^ @name.hash
          end

          def eql?(other)
            return false unless other.is_a?(self.class)
            @owner == other.owner && @name == other.name
          end

          def ==(other)
            eql?(other)
          end

          def to_def
            types = @types ? @types.map(&:to_def).join(', ') : 'none'
            message = "#{owner.type}.#{name}"
            message += ':virtual' if virtual
            "#{message}<#{types}>"
          end

          def to_s
            message = "Attribute #{owner.type}.#{name}"
            message = "#{message} (virtual)" if virtual
            types = @types ? @types.map(&:to_def).join(', ') : 'none'
            "#{message} <#{types}>"
          end

          private

          def validate_owner!(owner)
            return owner if owner.is_a?(Type)
            message = 'Provided owner has to be a Type instance,' \
              " #{owner.class} received"
            compliance_error(message)
          end

          def validate_name!(name)
            return name if name.is_a?(Symbol)
            message = "Provided name has to be Symbol, #{name.class} received"
            compliance_error(message)
          end

          def validate_types!(types)
            compliance_error("No types provided for #{self}") if types.empty?
            types.each do |type|
              next if type.is_a?(Type) || type.is_a?(Parameter)
              message = 'Provided type has to be a Type instance, ' \
                "#{type.class} received"
              compliance_error(message)
            end
          end
        end
      end
    end
  end
end
