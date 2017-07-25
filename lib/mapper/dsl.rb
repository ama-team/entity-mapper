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
            Mapper.types.register(Type::Concrete.new(klass))
            klass.class_eval do
              include ClassMethods
            end
          end
        end
      end
    end
  end
end
