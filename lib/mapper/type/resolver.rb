# frozen_string_literal: true

require_relative '../mixin/errors'
require_relative '../type'
require_relative 'parameter'

module AMA
  module Entity
    class Mapper
      class Type
        # This class is responsible for resolution of simple type definitions,
        # converting definitions like
        # [Array, T: [NilClass, [Hash, K: Symbol, V: Integer]]]
        # into real type hierarchy
        class Resolver
          include Mixin::Errors

          # @param [Registry] registry
          def initialize(registry)
            @registry = registry
          end

          def resolve(definition)
            definition = [definition] unless definition.is_a?(Enumerable)
            resolve_definition(definition)
          rescue StandardError => parent
            message = "Definition #{definition} resolution resulted " \
              "in error: #{parent}"
            compliance_error(message)
          end

          private

          def resolve_definitions(definitions)
            definitions = [definitions] unless definitions.is_a?(Array)
            if definitions.size == 2 && definitions.last.is_a?(Hash)
              definitions = [definitions]
            end
            definitions.map do |definition|
              resolve_definition(definition)
            end
          end

          def resolve_definition(definition)
            definition = [definition] unless definition.is_a?(Array)
            type = definition.first
            parameters = definition[1] || {}
            resolve_type(type, parameters)
          rescue StandardError => e
            message = "Unexpected error during definition #{definition} " \
              "resolution: #{e.message}"
            compliance_error(message)
          end

          def resolve_type(type, parameters)
            type = find_type(type)
            unless parameters.is_a?(Hash)
              message = "Type parameters were passed not as hash: #{parameters}"
              compliance_error(message)
            end
            parameters.each do |parameter, replacements|
              parameter = resolve_type_parameter(type, parameter)
              replacements = resolve_definitions(replacements)
              type = type.resolve_parameter(parameter, replacements)
            end
            type
          end

          def find_type(type)
            return type if type.is_a?(Type)
            if type.is_a?(Class) || type.is_a?(Module)
              return @registry[type] || Type::Analyzer.analyze(type)
            end
            message = 'Invalid type provided for resolution, expected Type, ' \
              "Class or Module: #{type}"
            compliance_error(message)
          end

          def resolve_type_parameter(type, parameter)
            unless parameter.is_a?(Parameter)
              parameter = find_parameter(type, parameter)
            end
            return parameter if parameter.owner.type == type.type
            message = "Parameter #{parameter} belongs to different type " \
              'rather one it is resolved against'
            compliance_error(message)
          end

          def find_parameter(type, parameter)
            parameter = parameter.to_sym if parameter.respond_to?(:to_sym)
            unless parameter.is_a?(Symbol)
              message = "#{parameter} is not a valid parameter identifier " \
                '(Symbol expected)'
              compliance_error(message)
            end
            return type.parameters[parameter] if type.parameters.key?(parameter)
            message = "Type #{type} has no requested parameter #{parameter}"
            compliance_error(message)
          end
        end
      end
    end
  end
end
