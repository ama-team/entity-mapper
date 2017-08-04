# frozen_string_literal: true

require_relative '../../type'
require_relative '../../mixin/errors'
require_relative 'primitive_type/denormalizer'

module AMA
  module Entity
    class Mapper
      class Type
        module BuiltIn
          # Predefined type for Set class
          class PrimitiveType < Type
            include Mixin::Errors

            def initialize(type, method_map)
              super(type)
              this = self

              factory_block do |*|
                this.compliance_error("#{this} factory should never be called")
              end
              normalizer_block do |entity, *|
                entity
              end
              self.denormalizer = Denormalizer.new(method_map)
              enumerator_block do |*|
                Enumerator.new { |*| }
              end
              injector_block { |*| }
            end

            # This hash describes which helper methods may be used for which
            # type to extract target primitive. During the run inheritance chain
            # is unwrapped, and first matching entry (topmost one) is used.
            primitives = {
              Symbol => { Object => [], String => %i[to_sym] },
              String => { Object => [], Symbol => %i[to_s] },
              Numeric => { Object => %i[to_i to_f], String => [] },
              Integer => { Object => %i[to_i], String => [] },
              Float => { Object => %i[to_f], String => [] },
              TrueClass => { Object => %i[to_b to_bool], String => [] },
              FalseClass => { Object => %i[to_b to_bool], String => [] },
              NilClass => { Object => [] }
            }

            # rubocop:disable Lint/UnifiedInteger
            if defined?(Fixnum)
              primitives[Fixnum] = { Object => %i[to_i], String => [] }
            end
            # rubocop:enable Lint/UnifiedInteger

            ALL = primitives.map do |klass, method_map|
              const_set(klass.to_s.upcase, new(klass, method_map))
            end
          end
        end
      end
    end
  end
end
