# frozen_String_literal: true

require_relative '../mixin/errors'
require_relative 'parameter'
require_relative 'hardwired/enumerable_type'
require_relative 'hardwired/array_type'
require_relative 'hardwired/hash_type'
require_relative 'hardwired/hash_tuple_type'
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

          # @return [AMA::Entity::Mapper::Type::Registry]
          def with_default_types
            register(Hardwired::EnumerableType::INSTANCE)
            register(Hardwired::ArrayType::INSTANCE)
            register(Hardwired::HashType::INSTANCE)
            register(Hardwired::SetType::INSTANCE)
            register(Hardwired::HashTupleType::INSTANCE)
            Hardwired::PrimitiveType::ALL.each do |type|
              register(type)
            end
            self
          end

          # @param [Class, Module] klass
          def [](klass)
            @types[klass]
          end

          # @param [AMA::Entity::Mapper::Type] type
          def register(type)
            @types[type.type] = type
          end

          # @param [Class] klass
          def key?(klass)
            @types.key?(klass)
          end

          alias registered? key?

          # @param [Class, Module] klass
          # @return [Array<AMA::Entity::Mapper::Type>]
          def select(klass)
            types = class_hierarchy(klass).map do |entry|
              @types[entry]
            end
            types.reject(&:nil?)
          end

          # @param [Class, Module] klass
          # @return [AMA::Entity::Mapper::Type, NilClass]
          def find(klass)
            candidates = select(klass)
            candidates.empty? ? nil : candidates.first
          end

          # @param [Class, Module] klass
          # @return [AMA::Entity::Mapper::Type]
          def find!(klass)
            candidate = find(klass)
            return candidate if candidate
            message = "Could not find any registered type for class #{klass}"
            compliance_error(message)
          end

          # @param [Class, Module] klass
          # @return [TrueClass, FalseClass]
          def resolvable?(klass)
            !select(klass).empty?
          end

          private

          # @param [Class, Module] klass
          def class_hierarchy(klass)
            ptr = klass
            chain = []
            loop do
              chain.push(*class_with_modules(ptr))
              break if !ptr.respond_to?(:superclass) || ptr.superclass.nil?
              ptr = ptr.superclass
            end
            chain
          end

          def class_with_modules(klass)
            if klass.superclass.nil?
              parent_modules = []
            else
              parent_modules = klass.superclass.included_modules
            end
            [klass, *(klass.included_modules - parent_modules)]
          end
        end
      end
    end
  end
end
