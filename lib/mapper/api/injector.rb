# frozen_string_literal: true

# rubocop:disable Lint/UnusedMethodArgument

require_relative 'interface'

module AMA
  module Entity
    class Mapper
      module API
        # Class that proxies attribute setting on target entity. That allows
        # tricks like virtual attribute handling or multi-value attribute
        # handling (like in hash or array)
        class Injector < Interface
          # :nocov:
          # Injects passed attribute into entity.
          #
          # @param [Object] entity
          # @param [AMA::Entity::Mapper::Type] type
          # @param [AMA::Entity::Mapper::Type::Attribute] attribute
          # @param [Object] value
          # @param [AMA::Entity::Mapper::Context] context
          def inject(entity, type, attribute, value, context = nil)
            abstract_method
          end
          # :nocov:
        end
      end
    end
  end
end
