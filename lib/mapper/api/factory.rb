# frozen_string_literal: true

# rubocop:disable Lint/UnusedMethodArgument

require_relative 'interface'

module AMA
  module Entity
    class Mapper
      module API
        # This interface depicts factory for class instance creation.
        class Factory < Interface
          # @param [AMA::Entity::Mapper::Type] type Type that requires creation.
          #   While most probably it wouldn't be necessary, it is unknown until
          #   creation which exact type will be used (altering type parameters
          #   results in new type creation)
          # @param [AMA::Entity::Mapper::Context] context
          # @param [Object] data Data that will be used for object creation.
          #   May be of any type or even nil.
          # @return [Object] Object of passed type.
          def create(type, context = nil, data = nil)
            abstract_method
          end
        end
      end
    end
  end
end
