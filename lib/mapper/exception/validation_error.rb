# frozen_string_literal: true

module AMA
  module Entity
    class Mapper
      module Exception
        # Made to be thrown if validation fails
        class ValidationError < RuntimeError
          include Exception
        end
      end
    end
  end
end
