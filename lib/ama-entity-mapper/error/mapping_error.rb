# frozen_string_literal: true

module AMA
  module Entity
    class Mapper
      module Error
        # Made to be thrown whenever mapping can't be done
        class MappingError < RuntimeError
          include Error
        end
      end
    end
  end
end
