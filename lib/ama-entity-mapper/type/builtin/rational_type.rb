# frozen_string_literal: true

require_relative '../../type'
require_relative '../../mixin/errors'

module AMA
  module Entity
    class Mapper
      class Type
        module BuiltIn
          # Rational type description
          class RationalType < Type
            def initialize
              super(Rational)

              normalizer_block do |entity, *|
                entity.to_s
              end

              define_denormalizer
              define_factory

              enumerator_block do |*|
                ::Enumerator.new { |*| }
              end

              injector_block { |*| }
            end

            private

            def define_denormalizer
              denormalizer_block do |input, _, ctx|
                break input if input.is_a?(Rational)
                input = input.to_s if input.is_a?(Symbol)
                break Rational(input) if input.is_a?(String)
                singleton_class.send(:include, Mixin::Errors)
                message = "String input expected (like '2.3'), " \
                  "#{input.class} received: #{input}"
                mapping_error(message, context: ctx)
              end
            end

            def define_factory
              factory_block do |_, _, ctx|
                singleton_class.send(:include, Mixin::Errors)
                message = 'Rational type could not be instantiated directly, ' \
                  'it only supports normalization and denormalization'
                compliance_error(message, context: ctx)
              end
            end

            INSTANCE = new
          end
        end
      end
    end
  end
end
