# frozen_string_literal: true

require_relative '../concrete'
require_relative '../aux/pair'

module AMA
  module Entity
    class Mapper
      class Type
        module Hardwired
          # Pair class definition
          class PairType < Concrete
            def initialize
              super(Aux::Pair)

              attribute!(:left, parameter!(:L))
              attribute!(:right, parameter!(:R))
            end
          end
        end
      end
    end
  end
end
