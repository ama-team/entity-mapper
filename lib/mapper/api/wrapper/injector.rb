# frozen_string_literal: true

require_relative '../injector'
require_relative '../default/injector'
require_relative '../../context'
require_relative '../../mixin/errors'

module AMA
  module Entity
    class Mapper
      module API
        module Wrapper
          # Default attribute injector
          class Injector < API::Injector
            include Mixin::Errors

            # @param [AMA::Entity::Mapper::API::Injector] processor
            def initialize(processor)
              @processor = processor
              @fallback = Default::Injector::INSTANCE
            end

            # @param [Object] entity
            # @param [AMA::Entity::Mapper::Type] type
            # @param [AMA::Entity::Mapper::Type::Attribute] attribute
            # @param [Object] value
            # @param [AMA::Entity::Mapper::Context] context
            def inject(entity, type, attribute, value, context = nil)
              ctx = context || Context.new
              attr = attribute
              val = value
              @processor.inject(entity, type, attr, val, ctx) do |e, t, a, v, c|
                @fallback.inject(e, t, a, v, c)
              end
            rescue StandardError => e
              raise_if_internal(e)
              message = "Error while injecting #{attr} into #{entity} " \
                "(type: #{type}) using #{@processor}"
              if e.is_a?(ArgumentError)
                message += "Does #{@processor}#inject have signature " \
                  '(entity, type, attribute, value, context = nil)?'
              end
              mapping_error(message, parent: e, context: ctx)
            end
          end
        end
      end
    end
  end
end
