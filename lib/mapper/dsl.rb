# frozen_string_literal: true

require_relative 'type/concrete'
require_relative 'dsl/class_methods'

module AMA
  module Entity
    class Mapper
      # Entrypoint module for inclusion in target entities
      module DSL
        class << self
          def included(klass)
            klass.class_eval do
              include ClassMethods
              self.mapper = Mapper.handler
            end
          end
        end
      end
    end
  end
end
