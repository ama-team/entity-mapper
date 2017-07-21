# frozen_string_literal: true

require_relative '../../mixin/errors'

module AMA
  module Entity
    class Mapper
      class Type
        class Concrete < Type
          # Default implementation for type factory
          class Factory
            include Mixin::Errors

            # @param [AMA::Entity::Mapper::Type::Concrete] type
            def initialize(type)
              @type = type
            end

            # @param [AMA::Entity::Mapper::Context] context
            # @param [Object] _data
            def create(context = nil, _data = nil)
              @type.type.new
            rescue StandardError => e
              message = "Failed to create #{@type} instance directly from class"
              if e.is_a?(ArgumentError)
                message += '. Does it have parameterless #initialize() method?'
              end
              mapping_error(message, context: context, parent: e)
            end
          end
        end
      end
    end
  end
end
