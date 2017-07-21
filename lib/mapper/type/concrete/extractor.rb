# frozen_string_literal: true

require_relative '../../path/segment'
require_relative '../../mixin/errors'

module AMA
  module Entity
    class Mapper
      class Type
        class Concrete < Type
          # Extracts type attributes out of external source
          class Extractor < ::Enumerator
            include Mixin::Errors

            def initialize(type, object)
              validate_input(object, type)
              super() do |yielder|
                type.attributes.values.each do |attribute|
                  next if attribute.virtual
                  value = object[attribute.name]
                  segment = Path::Segment.index(attribute.name)
                  yielder << [attribute, value, segment]
                end
              end
            end

            private

            def validate_input(input, type)
              return if input.is_a?(Hash)
              message = 'Default extractor works only with hashes, ' \
                "but received #{input.class} for #{type}. Please substitute " \
                'extractor with custom implementation if that is expected.'
              mapping_error(message)
            end
          end
        end
      end
    end
  end
end
