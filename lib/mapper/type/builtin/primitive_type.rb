# frozen_string_literal: true

require_relative '../../type'
require_relative '../../mixin/errors'

module AMA
  module Entity
    class Mapper
      class Type
        module BuiltIn
          # Predefined type for Set class
          class PrimitiveType < Type
            include Mixin::Errors

            def initialize(type, *methods, &denormalizer)
              super(type)
              this = self

              factory_block do |*|
                this.compliance_error("#{this} factory should never be called")
              end
              normalizer_block do |entity, *|
                entity
              end
              denormalizer = default_denormalizer(methods) unless denormalizer
              denormalizer_block(&denormalizer)
              enumerator_block do |*|
                Enumerator.new { |*| }
              end
              injector_block { |*| }
            end

            private

            def default_denormalizer(methods)
              lambda do |input, type, context|
                break input if type.valid?(input, context)
                candidate = methods.reduce(nil) do |carrier, method|
                  next carrier if carrier || !input.respond_to?(method)
                  input.send(method)
                end
                break candidate if candidate
                message = "Can't create #{type} instance from #{input.class}"
                type.mapping_error(message, context: context)
              end
            end

            primitives = {
              Symbol => %i[to_sym],
              String => [],
              Numeric => %i[to_i to_f],
              Integer => %i[to_i],
              Float => %i[to_f],
              TrueClass => %i[to_bool],
              FalseClass => %i[to_bool],
              NilClass => []
            }

            # rubocop:disable Lint/UnifiedInteger
            primitives[Fixnum] = %i[to_i] if defined?(Fixnum)
            # rubocop:enable Lint/UnifiedInteger

            ALL = primitives.map do |klass, methods|
              const_set(klass.to_s.upcase, new(klass, *methods))
            end

            STRING.denormalizer_block do |input, type, context|
              input = input.to_s if input.is_a?(Symbol)
              break input if input.is_a?(String)
              message = "Can't create #{type} instance from #{input.class}"
              type.mapping_error(message, context: context)
            end
          end
        end
      end
    end
  end
end
