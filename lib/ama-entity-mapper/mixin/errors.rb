# frozen_string_literal: true

require_relative '../error'
require_relative '../error/mapping_error'
require_relative '../error/compliance_error'
require_relative '../error/validation_error'

module AMA
  module Entity
    class Mapper
      module Mixin
        # Simple mixin that provides shortcuts for raising common errors
        module Errors
          error_types = %i[Mapping Compliance Validation]
          error_namespace = ::AMA::Entity::Mapper::Error

          # @!method mapping_error(message, **options)
          #   @param [String] message

          # @!method compliance_error(message, **options)
          #   @param [String] message

          # @!method validation_error(message, **options)
          #   @param [String] message
          error_types.each do |type|
            method = "#{type.to_s.downcase}_error"
            error_class = error_namespace.const_get("#{type}Error")
            define_method method do |message, **options|
              parent_error = options[:parent]
              unless parent_error.nil?
                if options[:signature] && parent_error.is_a?(ArgumentError)
                  message += '.' if /\w$/ =~ message
                  message += ' Does called method have signature ' \
                    "#{options[:signature]}?"
                end
                message += '.' if /\w$/ =~ message
                message += " Parent error: #{parent_error.message}"
              end
              if options[:context]
                message += " (path: #{options[:context].path})"
              end
              raise error_class, message
            end
          end

          # Raises error again if this is an internal error
          # @param [Exception] e
          def raise_if_internal(e)
            raise e if e.is_a?(Mapper::Error)
          end
        end
      end
    end
  end
end
