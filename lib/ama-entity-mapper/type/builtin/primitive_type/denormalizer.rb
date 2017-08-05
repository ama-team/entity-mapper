# frozen_string_literal: true

require_relative '../../../type'
require_relative '../../../mixin/errors'

module AMA
  module Entity
    class Mapper
      class Type
        module BuiltIn
          class PrimitiveType < Type
            # Standard denormalizer for primitive type
            class Denormalizer
              include Mixin::Errors

              # @param [Hash{Class, Array<Symbol>}] method_map
              def initialize(method_map)
                @method_map = method_map
              end

              # @param [Object] source
              # @param [AMA::Entity::Mapper::Type] type
              # @param [AMA::Entity::Mapper::Context] context
              def denormalize(source, type, context)
                return source if type.valid?(source, context)
                find_candidate_methods(source.class).each do |candidate|
                  begin
                    next unless source.respond_to?(candidate)
                    value = source.send(candidate)
                    return value if type.valid?(value, context)
                  rescue StandardError => e
                    message = "Method #{candidate} failed with error when " \
                      "denormalizing #{type.type} out of #{source.class}: " \
                      "#{e.message}"
                    context.logger.warn(message)
                  end
                end
                message = "Can't create #{type} instance from #{source.class}"
                mapping_error(message, context: context)
              end

              private

              def find_candidate_methods(klass)
                chain = []
                cursor = klass
                until cursor.nil?
                  chain.push(cursor)
                  cursor = cursor.superclass
                end
                winner = chain.find do |entry|
                  @method_map.key?(entry)
                end
                winner.nil? ? [] : @method_map[winner]
              end
            end
          end
        end
      end
    end
  end
end
