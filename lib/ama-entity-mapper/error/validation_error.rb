# frozen_string_literal: true

module AMA
  module Entity
    class Mapper
      module Error
        # Made to be thrown if validation fails
        class ValidationError < RuntimeError
          include Error
        end
      end
    end
  end
end
