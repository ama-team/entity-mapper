# frozen_string_literal: true

module AMA
  module Entity
    class Mapper
      # Used to describe generic types, for example, Hash{Symbol, CustomClass}
      # will be described as GenericType.new(Hash, Symbol, CustomClass)
      class GenericType
        attr_reader :type
        attr_reader :parameters

        def initialize(type, *parameters)
          @type = type
          @parameters = parameters
        end
      end
    end
  end
end
