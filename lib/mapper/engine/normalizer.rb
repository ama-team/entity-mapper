# frozen_string_literal: true

require_relative 'context'
require_relative '../mixin/errors'

module AMA
  module Entity
    class Mapper
      class Engine
        # Class for conversion of any passed structure down to basic primitives
        # - strings, hashes, etc.
        class Normalizer
          include Mixin::Errors

          def normalize(value, source_type, context = nil)
            context ||= Context.new
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
