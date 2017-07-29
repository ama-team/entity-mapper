# frozen_string_literal: true

require_relative '../mixin/errors'
require_relative '../context'

module AMA
  module Entity
    class Mapper
      class Engine
        # Class for conversion of any passed structure down to basic primitives
        # - strings, hashes, etc. Delegates actual work to type normalizer
        # and adds security wrap.
        class Normalizer
          include Mixin::Errors

          # @param [Object] value
          # @param [AMA::Entity::Mapper::Type] source_type
          # @param [AMA::Entity::Mapper::Context] context
          # @return [Object]
          def normalize(value, source_type, context)
            normalizer = source_type.normalizer
            normalizer.normalize(value, source_type, context)
          rescue StandardError => e
            raise_if_internal(e)
            message = "Error while normalizing #{value.class}"
            mapping_error(message, context: context, parent: e)
          end
        end
      end
    end
  end
end
