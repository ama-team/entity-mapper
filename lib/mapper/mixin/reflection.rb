# frozen_string_literal: true

require_relative 'errors'

module AMA
  module Entity
    class Mapper
      module Mixin
        # Collection of common methods twiddling with object internals
        module Reflection
          def populate_object(object, values)
            values.each do |key, value|
              begin
                method = "#{key}="
                next object.send(method, value) if object.respond_to?(method)
                object.instance_variable_set("@#{key}", value)
              rescue StandardError => e
                message = "Failed to set attribute #{key} to #{object.class}"
                mapping_error message, e
              end
            end
            object
          end

          def object_variables(object)
            intermediate = object.instance_variables.map do |variable|
              [variable[1..-1].to_sym, object.instance_variable_get(variable)]
            end
            Hash[intermediate]
          end
        end
      end
    end
  end
end
