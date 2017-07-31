# frozen_string_literal: true

require_relative 'errors'

module AMA
  module Entity
    class Mapper
      module Mixin
        # Collection of common methods twiddling with object internals
        module Reflection
          include Errors

          # @param [Object] object
          # @param [String, Symbol] name
          # @param [Object] value
          def set_object_attribute(object, name, value)
            method = "#{name}="
            return object.send(method, value) if object.respond_to?(method)
            object.instance_variable_set("@#{name}", value)
          rescue StandardError => e
            message = "Failed to set attribute #{name} on #{object.class}"
            mapping_error(message, parent: e)
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

          def object_variable_exists(object, name)
            object.instance_variables.include?("@#{name}".to_sym)
          end

          def install_object_method(object, name, handler)
            compliance_error('Handler not provided') unless handler
            object.define_singleton_method(name, &handler)
            object
          end

          def method_object(method, to_s: nil, &handler)
            object = install_object_method(Object.new, method, handler)
            unless to_s
              to_s = "Wrapper object for proc #{handler} " \
                "(installed as method #{method})"
            end
            object.define_singleton_method(:to_s) do
              to_s
            end
            object
          end
        end
      end
    end
  end
end
