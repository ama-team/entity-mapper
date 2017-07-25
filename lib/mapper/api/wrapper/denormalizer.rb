# frozen_string_literal: true

require_relative '../denormalizer'
require_relative '../default/denormalizer'
require_relative '../../mixin/errors'
require_relative '../../context'

module AMA
  module Entity
    class Mapper
      module API
        module Wrapper
          # Denormalizer safety wrapper
          class Denormalizer < API::Denormalizer
            include Mixin::Errors

            # @param [AMA::Entity::Mapper::API::Denormalizer] processor
            def initialize(processor)
              @processor = processor
              @fallback = Default::Denormalizer::INSTANCE
            end

            # @param [Object] entity
            # @param [Hash] source
            # @param [AMA::Entity::Mapper::Type] type
            # @param [AMA::Entity::Mapper::Context] context
            def denormalize(entity, source, type, context = nil)
              ctx = context || Context.new
              @processor.denormalize(entity, source, type, ctx) do |e, s, t, c|
                @fallback.denormalize(e, s, t, c)
              end
            rescue StandardError => e
              raise_if_internal(e)
              message = "Error while denormalizing #{entity.class} " \
                "(type: #{type}) from #{source.class} using #{@processor}"
              if e.is_a?(ArgumentError)
                message += "Does #{@processor}#denormalize have signature " \
                  '(entity, source, type, context = nil)?'
              end
              mapping_error(message, parent: e, context: ctx)
            end
          end
        end
      end
    end
  end
end
