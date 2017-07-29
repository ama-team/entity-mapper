# frozen_string_literal: true

require_relative '../exception'
require_relative '../exception/mapping_error'
require_relative '../exception/compliance_error'

module AMA
  module Entity
    class Mapper
      module Mixin
        # Simple mixin that provides shortcuts for raising common errors
        module Errors
          error_types = %i[Mapping Compliance]
          error_namespace = ::AMA::Entity::Mapper::Exception

          # @!method mapping_error(message, **options)
          #   @param [String] message

          # @!method compliance_error(message, **options)
          #   @param [String] message
          error_types.each do |type|
            method = "#{type.to_s.downcase}_error"
            error_class = error_namespace.const_get("#{type}Error")
            define_method method do |message, parent_error = nil, **options|
              # TODO: deprecate parent_error parameter
              parent_error = options[:parent] unless parent_error
              if options[:context]
                message += " (path: #{options[:context].path})"
              end
              unless parent_error.nil?
                message += '.' if /\w$/ =~ message
                message += " Parent error: #{parent_error.message}"
              end
              raise error_class, message
            end
          end

          # Raises error again if this is an internal error
          # @param [Exception] e
          def raise_if_internal(e)
            raise e if e.is_a?(Mapper::Exception)
          end
        end
      end
    end
  end
end
