# frozen_string_literal: true

# rubocop:disable Lint/UnusedMethodArgument

require_relative 'mixin/errors'
require_relative 'context'

module AMA
  module Entity
    class Mapper
      # Base abstract class for all other types
      class Type
        include Mixin::Errors

        # :nocov:
        def initialize
          message = "#{self.class} is an abstract class " \
            'and can\'t be isntantiated directly'
          compliance_error(message)
        end
        # :nocov:

        # @return [Hash{Symbol, AMA::Entity::Mapper::Type::Attribute}]
        def attributes
          {}
        end

        # @return [Hash{Symbol, AMA::Entity::Mapper::Type}]
        def parameters
          {}
        end

        # @param [Symbol] id
        # @return [TrueClass, FalseClass]
        def attribute?(id)
          attributes.key?(id.to_sym)
        end

        # @param [Symbol] id
        # @return [TrueClass, FalseClass]
        def parameter?(id)
          parameters.key?(id.to_sym)
        end

        # :nocov:
        # Creates parameter if it doesn't yet exist and returns it
        #
        # @param [Symbol] id
        def parameter!(id)
          abstract_method
        end

        # @param [AMA::Entity::Mapper::Type] parameter
        # @param [AMA::Entity::Mapper::Type] substitution
        # @return [AMA::Entity::Mapper::Type]
        def resolve_parameter(parameter, substitution)
          abstract_method
        end
        # :nocov:

        # rubocop:disable Metrics/LineLength

        # @param [Hash<AMA::Entity::Mapper::Type, AMA::Entity::Mapper::Type>] parameters
        # @return [AMA::Entity::Mapper::Type]
        def resolve(parameters)
          parameters.reduce(self) do |carrier, tuple|
            carrier.resolve_parameter(*tuple)
          end
        end

        # rubocop:enable Metrics/LineLength

        # @return [TrueClass, FalseClass]
        def resolved?
          attributes.values.all?(&:resolved?)
        end

        # Validates that type is fully resolved, otherwise raises an error
        # @param [AMA::Entity::Mapper::Context] context
        def resolved!(context = nil)
          context ||= Context.new
          attributes.values.each do |attribute|
            attribute.resolved!(context)
          end
        end

        # :nocov:
        # @param [Object] object
        def instance?(object)
          abstract_method
        end
        # :nocov:

        # @param [Object] object
        # @param [AMA::Entity::Mapper::Context] context
        def instance!(object, context = nil)
          return if instance?(object)
          message = "Expected to receive instance of #{self}, got " \
            "#{object.class}"
          validation_error(message, context: context)
        end

        def valid?(object, context)
          instance?(object) && violations(object, context).empty?
        end

        def valid!(object, context)
          instance!(object, context)
          violations = self.violations(object, context)
          return if violations.empty?
          message = 'Validation failed, following violations were discovered: '
          violations = violations.map do |attribute, violation, segment|
            "[#{attribute}: #{violation} (#{segment})]"
          end
          message += violations.join(', ')
          validation_error(message, context: context)
        end

        # :nocov:
        # @deprecated
        def satisfied_by?(object)
          abstract_method
        end

        def violations(object, context)
          abstract_method
        end

        def hash
          abstract_method
        end

        def eql?(other)
          abstract_method
        end
        # :nocov:

        def ==(other)
          eql?(other)
        end

        # :nocov:
        def to_s
          abstract_method
        end
        # :nocov:

        protected

        # :nocov:
        # rubocop:disable Performance/Caller
        def abstract_method
          message = "Abstract method #{caller[1]} hasn't been implemented " \
            "in class #{self.class}"
          raise message
        end
        # rubocop:enable Performance/Caller
        # :nocov:
      end
    end
  end
end
