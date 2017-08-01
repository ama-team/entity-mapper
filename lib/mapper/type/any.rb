# frozen_string_literal: true

require_relative '../type'
require_relative '../mixin/errors'

module AMA
  module Entity
    class Mapper
      class Type
        # Used as a wildcard to pass anything through
        class Any < Type
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

          def instance?(object, *)
            !object.nil?
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
            'Any Type'
          end

          def to_def
            '*'
          end
        end
      end
    end
  end
end
