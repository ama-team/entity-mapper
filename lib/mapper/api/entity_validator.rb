# frozen_string_literal: true

# rubocop:disable Lint/UnusedMethodArgument

require_relative 'interface'

module AMA
  module Entity
    class Mapper
      module API
        # Custom validator for entity
        class EntityValidator < Interface
          # :nocov:
          # @param [Object] entity
          # @param [Mapper::Type::Concrete] type
          # @param [Mapper::Context] context
          def validate!(entity, type, context)
            abstract_method
          end
          # :nocov:
        end
      end
    end
  end
end
