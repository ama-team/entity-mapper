# frozen_string_literal: true

require_relative 'dsl/class_methods'

module AMA
  module Entity
    class Mapper
      # Entrypoint module for inclusion in target entities
      module DSL
        class << self
          def included(klass)
            klass.singleton_class.instance_eval do
              include ClassMethods
            end
            klass.mapper = Mapper.handler
          end
        end
      end
    end
  end
end
