# frozen_string_literal: true

# rubocop:disable Lint/UnusedMethodArgument

require_relative 'interface'
require_relative '../mixin/errors'

module AMA
  module Entity
    class Mapper
      module API
        # Custom validator for attribute
        class AttributeValidator < Interface
          include Mixin::Errors
          # :nocov:
          # @param [Object] value Attribute value
          # @param [Mapper::Type::Attribute] attribute
          # @param [Mapper::Context] context
          # @return [Array<String>] List of violations
          def validate(value, attribute, context)
            abstract_method
          end
          # :nocov:
        end
      end
    end
  end
end
