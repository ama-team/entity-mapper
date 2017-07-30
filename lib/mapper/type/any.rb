# frozen_string_literal: true

require_relative 'concrete'
require_relative '../mixin/errors'

module AMA
  module Entity
    class Mapper
      class Type
        # Used as a wildcard to pass anything through
        class Any < Concrete
          include Mixin::Errors

          def initialize
            super(self.class)
          end

          INSTANCE = new

          def parameters
            {}
          end

          def attributes
            {}
          end

          def parameter!(*)
            compliance_error('Tried to declare parameter on Any type')
          end

          def resolve_parameter(*)
            self
          end

          def instance?(*)
            true
          end

          def violations(*)
            []
          end

          def hash
            self.class.hash
          end

          def eql?(other)
            other.is_a?(Type)
          end

          def ==(other)
            eql?(other)
          end

          def to_s
            '*'
          end
        end
      end
    end
  end
end
