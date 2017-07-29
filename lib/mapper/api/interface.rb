# frozen_string_literal: true

require_relative '../mixin/errors'

module AMA
  module Entity
    class Mapper
      module API
        # Common methods used to describe an interface
        class Interface
          include Mixin::Errors

          protected

          # :nocov:
          def abstract_method
            compliance_error('Abstract method called')
          end
          # :nocov:
        end
      end
    end
  end
end
