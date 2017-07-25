# frozen_string_literal: true

require_relative '../factory'
require_relative '../../mixin/errors'

module AMA
  module Entity
    class Mapper
      module API
        module Default
          # Default entity factory
          class Factory < API::Factory
            include Mixin::Errors

            INSTANCE = new

            # @param [AMA::Entity::Mapper::Type] type
            # @param [Object] _data
            # @param [AMA::Entity::Mapper::Context] context
            def create(type, _data, context = nil)
              type.type.new
            rescue StandardError => e
              message = "Failed to instantiate #{type} directly from class."
              if e.is_a?(ArgumentError)
                message += ' Does it have parameterless constructor?'
              end
              mapping_error(message, parent: e, context: context)
            end
          end
        end
      end
    end
  end
end
