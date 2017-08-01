# frozen_string_literal: true

require_relative 'errors'

module AMA
  module Entity
    class Mapper
      module Mixin
        # Special module with method for playing with error suppression
        module SuppressionSupport
          include Errors

          # Enumerates elements in enumerator, applying block to each one,
          # returning result or suppressing specified error. If no element
          # has succeeded, raises last error.
          #
          # @param [Enumerator] enumerator
          # @param [Class<? extends StandardError>] error
          def successful(enumerator, error = StandardError)
            suppressed = []
            enumerator.each do |*args|
              begin
                return yield(*args)
              rescue error => e
                suppressed.push(e)
              end
            end
            compliance_error('Empty enumerator passed') if suppressed.empty?
            raise suppressed.last
          end
        end
      end
    end
  end
end
