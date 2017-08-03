# frozen_string_literal: true

require_relative '../type'

module AMA
  module Entity
    class Mapper
      class Engine
        # Helper and self-explanatory engine class
        class RecursiveNormalizer
          # @param [AMA::Entity::Mapper::Type::Registry] registry
          def initialize(registry)
            @registry = registry
          end

          # @param [Object] entity
          # @param [AMA::Entity::Mapper::Context] ctx
          # @param [AMA::Entity::Mapper::Type, NilClass] type
          def normalize(entity, ctx, type = nil)
            type ||= find_type(entity.class)
            target = entity
            ctx.logger.debug("Normalizing #{entity.class} as #{type.type}")
            if type.virtual
              message = "Type #{type.type} is virtual, skipping to attributes"
              ctx.logger.debug(message)
            else
              target = type.normalizer.normalize(entity, type, ctx)
            end
            target_type = find_type(target.class)
            process_attributes(target, target_type, ctx)
          end

          private

          # @param [Object] entity
          # @param [AMA::Entity::Mapper::Type] type
          # @param [AMA::Entity::Mapper::Context] ctx
          def process_attributes(entity, type, ctx)
            if type.attributes.empty?
              message = "No attributes found on #{type.type}, returning " \
                "#{entity.class} as is"
              ctx.logger.debug(message)
              return entity
            end
            normalize_attributes(entity, type, ctx)
          end

          # @param [Object] entity
          # @param [AMA::Entity::Mapper::Type] type
          # @param [AMA::Entity::Mapper::Context] ctx
          def normalize_attributes(entity, type, ctx)
            message = "Normalizing attributes of #{entity.class} " \
              "(as #{type.type})"
            ctx.logger.debug(message)
            enumerator = type.enumerator.enumerate(entity, type, ctx)
            enumerator.each do |attribute, value, segment|
              local_ctx = ctx.advance(segment)
              value = normalize(value, local_ctx)
              type.injector.inject(entity, type, attribute, value, local_ctx)
            end
            entity
          end

          # @param [Class, Module] klass
          # @return [AMA::Entity::Mapper::Type]
          def find_type(klass)
            @registry.find(klass) || Type.new(klass)
          end
        end
      end
    end
  end
end
