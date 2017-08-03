# frozen_string_literal: true

require 'date'

require_relative '../../type'
require_relative '../../mixin/errors'

module AMA
  module Entity
    class Mapper
      class Type
        module BuiltIn
          # DateTime type description
          class DateTimeType < Type
            def initialize
              super(DateTime)

              normalizer_block do |entity, *|
                entity.iso8601(3)
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
                break input if input.is_a?(DateTime)
                input = input.to_s if input.is_a?(Symbol)
                break DateTime.iso8601(input, 3) if input.is_a?(String)
                if input.is_a?(Integer)
                  break DateTime.strptime(input.to_s, '%s')
                end
                singleton_class.send(:include, Mixin::Errors)
                message = 'String input expected (like ' \
                  "'2001-02-03T04:05:06.123+04:00'), " \
                  "#{input.class} received: #{input}"
                mapping_error(message, context: ctx)
              end
            end

            def define_factory
              factory_block do |_, _, ctx|
                singleton_class.send(:include, Mixin::Errors)
                message = 'DateTime type could not be instantiated directly, ' \
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
