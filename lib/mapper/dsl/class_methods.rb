# frozen_string_literal: true

require_relative '../mixin/reflection'

module AMA
  module Entity
    class Mapper
      module DSL
        # Module providing DSL methods for entity class
        module ClassMethods
          include Mixin::Reflection

          attr_reader :mapper

          def mapper=(mapper)
            @mapper = mapper
            mapper.register(self)
          end

          # @return [AMA::Entity::Mapper::Type::Concrete]
          def bound_type
            @mapper.types[self]
          end

          # @param [String, Symbol] name
          # @param [Array<AMA::Entity::Mapper::Type] types List of possible
          #   attribute types
          # @param [Hash] options Attribute options: :virtual, :sensitive
          # @return [AMA::Entity::Mapper::Type::Attribute]
          def attribute(name, *types, **options)
            types = types.map { |type| @mapper.resolve(type) }
            bound_type.attribute!(name, *types, **options)
          end

          # @param [String, Symbol] id
          # @return [AMA::Entity::Mapper::Type::Parameter]
          def parameter(id)
            bound_type.parameter!(id)
          end

          %i[factory enumerator injector normalizer denormalizer].each do |m|
            define_method m do |handler|
              bound_type.send(m, handler)
            end

            define_method "#{m}_block" do |&block|
              bound_type.send(m, &block)
            end
          end
        end
      end
    end
  end
end
