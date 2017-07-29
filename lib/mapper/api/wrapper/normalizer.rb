# frozen_string_literal: true

require_relative '../normalizer'
require_relative '../default/normalizer'
require_relative '../../context'
require_relative '../../mixin/errors'

module AMA
  module Entity
    class Mapper
      module API
        module Wrapper
          # Default attribute injector
          class Normalizer < API::Normalizer
            include Mixin::Errors

            # @param [AMA::Entity::Mapper::API::Normalizer] processor
            def initialize(processor)
              @processor = processor
              @fallback = Default::Normalizer::INSTANCE
            end

            # @param [Object] entity
            # @param [AMA::Entity::Mapper::Type] type
            # @param [AMA::Entity::Mapper::Context] context
            def normalize(entity, type, context = nil)
              ctx = context || Context.new
              @processor.normalize(entity, type, ctx) do |e, t, c|
                @fallback.normalize(e, t, c)
              end
            rescue StandardError => e
              raise_if_internal(e)
              message = "Error while normalizing #{entity} (type: #{type}) " \
                "using #{@processor}"
              if e.is_a?(ArgumentError)
                message += "Does #{@processor}#normalize have signature " \
                  '(entity, type, context = nil)?'
              end
              mapping_error(message, parent: e, context: ctx)
            end
          end
        end
      end
    end
  end
end
