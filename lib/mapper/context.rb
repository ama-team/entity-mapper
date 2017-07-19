# frozen_string_literal: true

require_relative 'path'
require_relative 'mixin/reflection'

module AMA
  module Entity
    class Mapper
      # Base class for various contexts, created to define common ground for
      # any traversal operations
      class Context
        include Mixin::Reflection

        # @!attribute path
        #   @return [AMA::Entity::Mapper::Path]
        attr_accessor :path

        def initialize(**options)
          defaults = respond_to?(:defaults) ? self.defaults : {}
          options = defaults.merge(options)
          defaults.keys.each do |key|
            instance_variable_set("@#{key}", options[key])
          end
        end

        def defaults
          {
            path: Path.new
          }
        end

        # Creates new context, resembling traversal to specified segment
        #
        # @param [AMA::Entity::Mapper::Path::Segment, String, Symbol] segment
        # @return [AMA::Entity::Mapper::Context]
        def advance(segment)
          data = to_h.merge(path: path.push(segment))
          self.class.new(**data)
        end

        def to_h
          object_variables(self)
        end
      end
    end
  end
end
