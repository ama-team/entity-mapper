# frozen_String_literal: true

require_relative '../mixin/errors'
require_relative 'concrete'
require_relative 'parameter'

module AMA
  module Entity
    class Mapper
      class Type
        # Holds all registered types
        class Registry
          include Mixin::Errors

          attr_accessor :types

          def initialize
            @types = {}
          end

          # @param [AMA::Entity::Mapper::Type::Concrete] type
          def register(type)
            @types[type.type] = type
          end

          # @param [Class] klass
          def registered?(klass)
            @types.key?(klass)
          end

          def for(klass)
            find_class_types(klass) | find_module_types(klass)
          end

          def find(klass)
            candidates = self.for(klass)
            candidates.empty? ? nil : candidates.first
          end

          def find!(klass)
            candidate = find(klass)
            return candidate if candidate
            message = "Could not find any registered type for class #{klass}"
            compliance_error(message)
          end

          def include?(klass)
            !find(klass).nil?
          end

          def [](klass)
            @types[klass]
          end

          def resolve(definition)
            if definition.is_a?(Module) || definition.is_a?(Class)
              definition = [definition]
            end
            klass, parameters = definition
            parameters ||= {}
            type = @types[klass] || Concrete.new(klass)
            parameters.each do |parameter, replacement|
              validate_replacement!(replacement)
              parameter = resolve_type_parameter(type, parameter)
              type = type.resolve_parameter(parameter, replacement)
            end
            type
          end

          private

          def validate_replacement!(replacement)
            return if replacement.is_a?(Type)
            message = 'Invalid parameter replacement supplied, ' \
              "expected Type, got #{replacement.class}"
            compliance_error(message)
          end

          def resolve_type_parameter(type, parameter)
            return parameter if parameter.is_a?(Parameter)
            if parameter.is_a?(Symbol) && type.parameter?(parameter)
              return type.parameters[parameter]
            end
            compliance_error("#{type} has no parameter #{parameter}")
          end

          def inheritance_chain(klass)
            cursor = klass
            chain = []
            loop do
              chain.push(cursor)
              cursor = cursor.superclass
              break if cursor.nil?
            end
            chain
          end

          def find_class_types(klass)
            inheritance_chain(klass).each_with_object([]) do |entry, carrier|
              carrier.push(types[entry]) if types[entry]
            end
          end

          def find_module_types(klass)
            chain = inheritance_chain(klass).reverse
            result = chain.reduce([]) do |carrier, entry|
              ancestor_types = entry.ancestors.map do |candidate|
                types[candidate]
              end
              carrier | ancestor_types.reject(&:nil?)
            end
            result.reverse
          end
        end
      end
    end
  end
end
