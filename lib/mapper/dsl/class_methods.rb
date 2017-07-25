# frozen_string_literal: true

require_relative '../mixin/reflection'

module AMA
  module Entity
    class Mapper
      module DSL
        # Module providing DSL methods for entity class
        module ClassMethods
          include Mixin::Reflection
          # @return [AMA::Entity::Mapper::Type::Concrete]
          def bound_type
            Mapper.types[self]
          end

          # @param [String, Symbol] name
          # @param [Array<AMA::Entity::Mapper::Type] types List of possible
          #   attribute types
          # @param [Hash] options Attribute options: :virtual, :sensitive
          # @return [AMA::Entity::Mapper::Type::Attribute]
          def attribute(name, *types, **options)
            types = types.map { |type| Mapper.types.resolve(type) }
            bound_type.attribute!(name, *types, **options)
          end

          # @param [String, Symbol] id
          # @return [AMA::Entity::Mapper::Type::Parameter]
          def parameter(id)
            bound_type.parameter!(id)
          end

          def enumerator=(enumerator)
            bound_type.enumerator = enumerator
          end

          def enumerator_block(&block)
            enumerator = install_object_method(Object.new, :enumerate, block)
            self.enumerator = enumerator
          end

          def injector=(injector)
            bound_type.injector = injector
          end

          def injector_block(&block)
            self.injector = install_object_method(Object.new, :inject, block)
          end

          def factory=(factory)
            bound_type.factory = factory
          end

          def factory_block(&block)
            self.factory = install_object_method(Object.new, :create, block)
          end

          def normalizer=(normalizer)
            bound_type.normalizer = normalizer
          end

          def normalizer_block(&block)
            n8r = install_object_method(Object.new, :normalize, block)
            self.normalizer = n8r
          end

          def denormalizer=(denormalizer)
            bound_type.denormalizer = denormalizer
          end

          def denormalizer_block(&block)
            d10r = install_object_method(Object.new, :denormalize, block)
            self.denormalizer = d10r
          end
        end
      end
    end
  end
end
