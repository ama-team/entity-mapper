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

        # @return [Hash{Symbol, AMA::Entity::Mapper::Type::Attribute}]
        def attributes
          abstract_method
        end

        # @return [Hash{Symbol, AMA::Entity::Mapper::Type}]
        def parameters
          abstract_method
        end

        # @param [Symbol] id
        # @return [TrueClass, FalseClass]
        def parameter?(id)
          parameters.key?(id)
        end

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

        # rubocop:enable Metrics/LineLength

        # @param [Hash<AMA::Entity::Mapper::Type, AMA::Entity::Mapper::Type>] parameters
        # @return [AMA::Entity::Mapper::Type]
        def resolve(parameters)
          parameters.reduce(self) do |carrier, tuple|
            carrier.resolve_parameter(*tuple)
          end
        end

        # @return [TrueClass, FalseClass]
        def resolved?
          attributes.values.all?(&:resolved?)
        end

        def resolved!(context = nil)
          context ||= Context.new
          attributes.values.each do |item|
            item.resolved!(context)
          end
        end

        # @param [Object] object
        def instance?(object)
          abstract_method
        end

        # @param [Object] object
        # @param [AMA::Entity::Mapper::Context] context
        def instance!(object, context = nil)
          return if instance?(object) || object.nil?
          message = "Expected to receive instance of #{self}, got " \
            "#{object.class}"
          mapping_error(message, context: context)
        end

        def satisfied_by?(object)
          abstract_method
        end

        # rubocop:disable Metrics/LineLength

        # Dissects object into pairs (triplets) of attribute and it's value
        # (and, optionally, path segment), then passes them one by one into
        # supplied block and assembles new type instance.
        #
        # @param [Object] object
        # @yieldparam attribute [AMA::Entity::Mapper::Type::Attribute]
        # @yieldparam value [Object]
        # @yieldparam segment [AMA::Entity::Mapper::Path::Segment] optional
        # @yieldreturn [Object] processed value
        def map(object)
          abstract_method
        end

        def hash
          abstract_method
        end

        def eql?(other)
          abstract_method
        end

        def ==(other)
          eql?(other)
        end

        def to_s
          abstract_method
        end

        protected

        def abstract_method
          message = "Abstract method #{__callee__} hasn't been implemented " \
            "in class #{self.class}"
          raise message
        end
      end
    end
  end
end
