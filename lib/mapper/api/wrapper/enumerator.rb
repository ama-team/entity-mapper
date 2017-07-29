# frozen_string_literal: true

require_relative '../enumerator'
require_relative '../default/enumerator'
require_relative '../../mixin/errors'
require_relative '../../context'

module AMA
  module Entity
    class Mapper
      module API
        module Wrapper
          # Denormalizer safety wrapper
          class Enumerator < API::Enumerator
            include Mixin::Errors

            # @param [AMA::Entity::Mapper::API::Enumerator] processor
            def initialize(processor)
              @processor = processor
              @fallback = Default::Enumerator::INSTANCE
            end

            # @param [Object] entity
            # @param [AMA::Entity::Mapper::Type] type
            # @param [AMA::Entity::Mapper::Context] context
            def enumerate(entity, type, context = nil)
              context ||= Context.new
              @processor.enumerate(entity, type, context) do |e, t, c|
                @fallback.enumerate(e, t, c)
              end
            rescue StandardError => e
              raise_if_internal(e)
              message = "Error while enumerating #{entity.class} " \
                "(type: #{type}) attributes using #{@processor}"
              if e.is_a?(ArgumentError)
                message += "Does #{@processor}#enumerate have signature " \
                  '(entity, type, context = nil)?'
              end
              mapping_error(message, parent: e, context: context)
            end
          end
        end
      end
    end
  end
end
