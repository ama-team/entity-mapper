# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

require_relative '../mixin/suppression_support'
require_relative '../mixin/errors'
require_relative '../error'
require_relative '../type'
require_relative '../type/analyzer'

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
            map_unsafe(source, types, context)
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
            epithet = reassembled ? 'reassembled' : 'source'
            if type.attributes.empty?
              message = "#{type.to_def} has no attributes, " \
                "returning #{epithet} instance"
              ctx.logger.debug(message)
              return source
            end
            process_attributes(source, type, ctx)
          end

          private

          # @param [Object] source
          # @param [Array<AMA::Entity::Mapper::Type] types
          # @param [AMA::Entity::Mapper::Context] context
          def map_unsafe(source, types, context)
            message = "Mapping #{source.class} into one of: " \
              "#{types.map(&:to_def).join(', ')}"
            context.logger.debug(message)
            successful(types, Mapper::Error, context) do |type|
              result = map_type(source, type, context)
              context.logger.debug("Validating resulting #{type.to_def}")
              type.valid!(result, context)
              result
            end
          end

          # @param [Object] source
          # @param [AMA::Entity::Mapper::Type] type
          # @param [AMA::Entity::Mapper::Context] ctx
          # @return [Object]
          def process_attributes(source, type, ctx)
            attributes = map_attributes(source, type, ctx)
            if attributes.select(&:first).empty?
              message = 'No changes in attributes detected, ' \
                "returning #{source.class}"
              ctx.logger.debug(message)
              return source
            end
            ctx.logger.debug("Creating new #{type.to_def} instance")
            target = type.factory.create(type, source, ctx)
            ctx.logger.debug("Installing #{type.to_def} attributes")
            install_attributes(target, type, attributes, ctx)
          end

          # Returns array of mapped attribute in format
          # [[changed?, attribute, value, attribute_context],..]
          # @param [Object] source
          # @param [AMA::Entity::Mapper::Type] type
          # @param [AMA::Entity::Mapper::Context] ctx
          # @return [Array]
          def map_attributes(source, type, ctx)
            ctx.logger.debug("Mapping #{source.class} attributes")
            enumerator = type.enumerator.enumerate(source, type, ctx)
            enumerator.map do |attribute, value, segment|
              local_ctx = segment.nil? ? ctx : ctx.advance(segment)
              mutated = map_attribute(value, attribute, local_ctx)
              changed = !mutated.equal?(value)
              if changed
                ctx.logger.debug("Attribute #{attribute.to_def} has changed")
              end
              [changed, attribute, mutated, local_ctx]
            end
          end

          # @param [Object] source
          # @param [AMA::Entity::Mapper::Type::Attribute] attribute
          # @param [AMA::Entity::Mapper::Context] context
          def map_attribute(source, attribute, context)
            message = "Extracting attribute #{attribute.to_def} " \
              "from #{source.class}"
            context.logger.debug(message)
            successful(attribute.types, Mapper::Error) do |type|
              if source.nil? && attribute.nullable
                context.logger.debug('Found legal nil, short-circuiting')
                break nil
              end
              result = map_type(source, type, context)
              context.logger.debug("Validating resulting #{attribute.to_def}")
              attribute.valid!(result, context)
              result
            end
          end

          # @param [Object] target
          # @param [AMA::Entity::Mapper::Type] type
          # @param [Array] attributes
          # @param [AMA::Entity::Mapper::Context] ctx
          def install_attributes(target, type, attributes, ctx)
            ctx.logger.debug("Installing updated attributes on #{type.to_def}")
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
              msg = "Not reassembling #{source.class}, already of target type"
              context.logger.debug(msg)
              return [source, false]
            end
            reassemble(source, type, context)
          end

          # @param [Object] source
          # @param [AMA::Entity::Mapper::Type] type
          # @param [AMA::Entity::Mapper::Context] context
          # @return [Object]
          def reassemble(source, type, context)
            message = "Reassembling #{source.class} as #{type.type}"
            context.logger.debug(message)
            source_type = @registry.find(source.class)
            source_type ||= Type::Analyzer.analyze(source.class)
            normalizer = source_type.normalizer
            normalized = normalizer.normalize(source, source_type, context)
            [type.denormalizer.denormalize(normalized, type, context), true]
          end
        end
      end
    end
  end
end
