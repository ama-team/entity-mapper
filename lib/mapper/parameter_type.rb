# frozen_string_literal: true

module AMA
  module Entity
    class Mapper
      # Used to fill in types that would be known later at runtime
      class ParameterType
        attr_reader :id

        def initialize(id)
          @id = id
        end
      end
    end
  end
end
