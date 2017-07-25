# frozen_string_literal: true

require_relative '../factory'
require_relative '../default/factory'
require_relative '../../mixin/errors'
require_relative '../../context'

module AMA
  module Entity
    class Mapper
      module API
        module Wrapper
          # Factory safety wrapper
          class Factory < API::Factory
            include Mixin::Errors

            # @param [AMA::Entity::Mapper::API::Factory] processor
            def initialize(processor)
              @processor = processor
              @fallback = Default::Factory::INSTANCE
            end

            # @param [AMA::Entity::Mapper::Type] type
            # @param [Object] data
            # @param [AMA::Entity::Mapper::Context] context
            def create(type, data, context = nil)
              context ||= Context.new
              @processor.create(type, data, context) do |t, d, c|
                @fallback.create(t, d, c)
              end
            rescue StandardError => e
              raise_if_internal(e)
              message = "Error while creatin #{type} instance " \
                "(type: #{type}) attributes using #{@processor}"
              if e.is_a?(ArgumentError)
                message += "Does #{@processor}#create have signature " \
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
