# frozen_string_literal: true

require_relative '../mixin/suppression_support'
require_relative '../mixin/errors'
require_relative '../error'
require_relative '../type'

module AMA
  module Entity
    class Mapper
      class Engine
        # Recursively maps object to one of specified types
        class RecursiveMapper
          include Mixin::SuppressionSupport
          include Mixin::Errors

          # @param [AMA::Entity::Mapper::Type::Registry] registry
          def initialize(registry)
            @registry = registry
          end

          # @param [Object] source
          # @param [Array<AMA::Entity::Mapper::Type] types
          # @param [AMA::Entity::Mapper::Context] context
          def map(source, types, context)
            successful(types, Mapper::Error) do |type|
              result = map_type(source, type, context)
              type.valid!(result, context)
              result
            end
          rescue StandardError => e
            message = "Failed to map #{source.class} " \
              "to any of provided types (#{types.map(&:to_def).join(', ')}). " \
              "Last error: #{e.message} in #{e.backtrace_locations[0]}"
            mapping_error(message)
          end

          # @param [Object] source
          # @param [AMA::Entity::Mapper::Type] type
          # @param [AMA::Entity::Mapper::Context] ctx
          # @return [Object]
          def map_type(source, type, ctx)
            ctx.logger.debug("Mapping #{source.class} to type #{type.to_def}")
            source, reassembled = request_reassembly(source, type, ctx)
            attributes = map_attributes(source, type, ctx)
            if attributes.select(&:first).empty?
              epithet = reassembled ? 'reassembled' : 'source'
              ctx.logger.debug("No changes detected, returning #{epithet} data")
              return source
            end
            target = type.factory.create(type, source, ctx)
            install_attributes(target, type, attributes, ctx)
          end

          private

          # Returns array of mapped attribute in format
          # [[changed?, attribute, value, attribute_context],..]
          # @param [Object] source
          # @param [AMA::Entity::Mapper::Type] type
          # @param [AMA::Entity::Mapper::Context] ctx
          # @return [Array]
          def map_attributes(source, type, ctx)
            ctx.logger.debug("Mapping #{source} attributes")
            enumerator = type.enumerator.enumerate(source, type, ctx)
            enumerator.map do |attribute, value, segment|
              local_ctx = segment.nil? ? ctx : ctx.advance(segment)
              mutated = map_attribute(value, attribute, local_ctx)
              changed = !mutated.equal?(value)
              ctx.logger.debug("#{attribute} has changed") if changed
              [changed, attribute, mutated, local_ctx]
            end
          end

          # @param [Object] source
          # @param [AMA::Entity::Mapper::Type::Attribute] attribute
          # @param [AMA::Entity::Mapper::Context] context
          def map_attribute(source, attribute, context)
            successful(attribute.types, Mapper::Error) do |type|
              break nil if source.nil? && attribute.nullable
              result = map_type(source, type, context)
              attribute.valid!(result, context)
              result
            end
          end

          # @param [Object] target
          # @param [AMA::Entity::Mapper::Type] type
          # @param [Array] attributes
          # @param [AMA::Entity::Mapper::Context] ctx
          def install_attributes(target, type, attributes, ctx)
            ctx.logger.debug('Installing updated attributes')
            attributes.each do |_, attribute, value, local_ctx|
              type.injector.inject(target, type, attribute, value, local_ctx)
            end
            target
          end

          # @param [Object] source
          # @param [AMA::Entity::Mapper::Type] type
          # @param [AMA::Entity::Mapper::Context] context
          # @return [Array<Object, TrueClass, FalseClass>]
          def request_reassembly(source, type, context)
            if type.instance?(source)
              message = "Not reassembling #{source} as #{type.to_def}, " \
                'already of target type'
              context.logger.debug(message)
              return [source, false]
            end
            reassemble(source, type, context)
          end

          # @param [Object] source
          # @param [AMA::Entity::Mapper::Type] type
          # @param [AMA::Entity::Mapper::Context] context
          # @return [Object]
          def reassemble(source, type, context)
            context.logger.debug("Reassembling #{source} as #{type.to_def}")
            source_type = @registry.find(source.class) || Type.new(source.class)
            normalizer = source_type.normalizer
            normalized = normalizer.normalize(source, source_type, context)
            [type.denormalizer.denormalize(normalized, type, context), true]
          end
        end
      end
    end
  end
end
