# frozen_string_literal: true

require_relative '../../mixin/reflection'
require_relative '../../path/segment'

module AMA
  module Entity
    class Mapper
      module Handler
        module Entity
          # Default attribute enumerator
          class Enumerator
            include Mixin::Reflection

            INSTANCE = new

            # @param [Object] entity
            # @param [AMA::Entity::Mapper::Type] type
            # @param [AMA::Entity::Mapper::Context] _context
            def enumerate(entity, type, _context)
              ::Enumerator.new do |yielder|
                type.attributes.values.each do |attribute|
                  next if attribute.virtual
                  next unless object_variable_exists(entity, attribute.name)
                  value = object_variable(entity, attribute.name)
                  segment = Path::Segment.attribute(attribute.name)
                  yielder << [attribute, value, segment]
                end
              end
            end

            class << self
              include Mixin::Reflection

              # @param [Enumerator] implementation
              # @return [Enumerator]
              def wrap(implementation)
                handler = handler_factory(implementation, INSTANCE)
                description = "Safety wrapper for #{implementation}"
                wrapper = method_object(:enumerate, to_s: description, &handler)
                wrapper.singleton_class.instance_eval do
                  include Mixin::Errors
                end
                wrapper
              end

              private

              # @param [Enumerator] implementation
              # @param [Enumerator] fallback
              # @return [Enumerator]
              def handler_factory(implementation, fallback)
                lambda do |entity, type, ctx|
                  begin
                    implementation.enumerate(entity, type, ctx) do |e, t, c|
                      fallback.enumerate(e, t, c)
                    end
                  rescue StandardError => e
                    raise_if_internal(e)
                    message = 'Unexpected error from enumerator ' \
                      "#{implementation}"
                    signature = '(entity, type, context)'
                    options = { parent: e, context: ctx, signature: signature }
                    compliance_error(message, **options)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
