# frozen_string_literal: true

# rubocop:disable Lint/UnusedMethodArgument

require_relative 'interface'

module AMA
  module Entity
    class Mapper
      module API
        # This special interface exists as a way for Mapper to non-directly
        # fetch all possible entity attributes
        class Enumerator < Interface
          # :nocov:
          # Enumerates entity attributes
          #
          # @param [Object] entity
          # @param [AMA::Entity::Mapper::Type] type
          # @param [AMA::Entity::Mapper::Context] context
          def enumerate(entity, type, context = nil)
            abstract_method
          end
          # :nocov:
        end
      end
    end
  end
end
