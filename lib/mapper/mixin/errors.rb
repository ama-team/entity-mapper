# frozen_string_literal: true

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

          # @!method mapping_error(message, parent_error = nil)
          #   @param [String] message
          #   @param [StandardError] parent_error
          # @!method compliance_error(message, parent_error = nil)
          #   @param [String] message
          #   @param [StandardError] parent_error
          error_types.each do |type|
            method = "#{type.to_s.downcase}_error"
            error_class = error_namespace.const_get("#{type}Error")
            define_method method do |message, parent_error = nil|
              message += ": #{parent_error.message}" unless parent_error.nil?
              raise error_class, message
            end
          end
        end
      end
    end
  end
end
