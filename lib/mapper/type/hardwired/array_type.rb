# frozen_string_literal: true

require_relative 'enumerable_type'

module AMA
  module Entity
    class Mapper
      class Type
        module Hardwired
          # Even though it is functionally unnecessary, end users are more
          # likely to call `Mapper.map(input, Array)` rather than
          # `Mapper.map(input, Enumerable)`. Because mapper has no right to
          # make assumptions about type children, it would have to back off to
          # standard hash-based normalization/denormalization, and that would
          # cause end-user frustration
          class ArrayType < EnumerableType
          end
        end
      end
    end
  end
end
