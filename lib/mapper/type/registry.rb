# frozen_String_literal: true

require_relative '../mixin/errors'
require_relative 'concrete'
require_relative 'parameter'
require_relative 'hardwired/enumerable_type'
require_relative 'hardwired/hash_type'
require_relative 'hardwired/pair_type'
require_relative 'hardwired/set_type'
require_relative 'hardwired/primitive_type'

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
          def key?(klass)
            @types.key?(klass)
          end

          alias registered? key?

          def applicable(klass)
            find_class_types(klass) | find_module_types(klass)
          end

          def find(klass)
            candidates = applicable(klass)
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

          def with_default_types
            register(Hardwired::EnumerableType::INSTANCE)
            register(Hardwired::HashType::INSTANCE)
            register(Hardwired::SetType::INSTANCE)
            register(Hardwired::PairType::INSTANCE)
            Hardwired::PrimitiveType::ALL.each do |type|
              register(type)
            end
            self
          end

          private

          def validate_replacement!(replacement, context = nil)
            return if replacement.is_a?(Type)
            message = 'Invalid parameter replacement supplied, expected Type ' \
              "instance, got #{replacement} (#{replacement.class})"
            compliance_error(message, context: context)
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
