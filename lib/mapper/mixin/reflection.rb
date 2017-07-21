# frozen_string_literal: true

require_relative 'errors'

module AMA
  module Entity
    class Mapper
      module Mixin
        # Collection of common methods twiddling with object internals
        module Reflection
          include Errors

          # @deprecated
          def populate_object(object, values)
            set_object_attributes(object, values)
          end

          def set_object_attributes(object, values)
            values.each do |attribute, value|
              set_object_attribute(object, attribute, value)
            end
            object
          end

          # @param [Object] object
          # @param [String, Symbol] name
          # @param [Object] value
          def set_object_attribute(object, name, value)
            method = "#{name}="
            return object.send(method, value) if object.respond_to?(method)
            object.instance_variable_set("@#{name}", value)
          rescue StandardError => e
            message = "Failed to set attribute #{name} on #{object.class}"
            mapping_error(message, e)
          end

          # @param [Object] object
          def object_variables(object)
            intermediate = object.instance_variables.map do |variable|
              [variable[1..-1].to_sym, object.instance_variable_get(variable)]
            end
            Hash[intermediate]
          end

          # @param [Object] object
          # @param [String, Symbol] name
          def object_variable(object, name)
            name = "@#{name}" unless name[0] == '@'
            object.instance_variable_get(name)
          end
        end
      end
    end
  end
end
