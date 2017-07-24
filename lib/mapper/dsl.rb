# frozen_string_literal: true

require_relative 'type/concrete'

module AMA
  module Entity
    class Mapper
      # Module to be included in user entities
      module DSL
        class << self
          def included(klass)
            Mapper.types.register(Type::Concrete.new(klass))
          end
        end

        # @return [AMA::Entity::Mapper::Type::Concrete]
        def bound_type
          Mapper.types[self.class]
        end

        # @param [String, Symbol] name
        # @param [Array<AMA::Entity::Mapper::Type] types List of possible
        #   attribute types
        # @param [Hash] options Attribute options: :virtual, :sensitive
        # @return [AMA::Entity::Mapper::Type::Attribute]
        def attribute(name, *types, **options)
          bound_type.attribute!(name, *types, **options)
        end

        # @param [String, Symbol] id
        # @return [AMA::Entity::Mapper::Type::Parameter]
        def parameter(id)
          bound_type.parameter!(id)
        end

        def extractor=(extractor)
          bound_type.extractor = extractor
        end

        def enumerator=(enumerator)
          bound_type.enumerator = enumerator
        end

        def acceptor=(acceptor)
          bound_type.acceptor = acceptor
        end

        def factory=(factory)
          bound_type.factory = factory
        end

        def normalizer=(normalizer)
          bound_type.normalizer = normalizer
        end

        def denormalizer=(denormalizer)
          bound_type.denormalizer = denormalizer
        end
      end
    end
  end
end
