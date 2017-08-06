# frozen_string_literal: true

require 'logger'

require_relative 'path'
require_relative 'mixin/reflection'
require_relative 'aux/null_stream'

module AMA
  module Entity
    class Mapper
      # Base class for various contexts, created to define common ground for
      # any traversal operations
      class Context
        include Mixin::Reflection

        # @!attribute [r] path
        #   @return [AMA::Entity::Mapper::Path]
        attr_reader :path
        # @!attribute [r] logger
        #   @return [Logger]
        attr_reader :logger
        # @!attribute [r] strict
        #   @return [FalseClass, TrueClass]
        attr_reader :strict
        # @!attribute [r] include_sensitive_attributes
        #   @return [FalseClass, TrueClass]
        attr_reader :include_sensitive_attributes

        def initialize(**options)
          defaults = respond_to?(:defaults) ? self.defaults : {}
          options = defaults.merge(options)
          defaults.keys.each do |key|
            instance_variable_set("@#{key}", options[key])
          end
          @logger = @logger.clone
          @logger.progname = "#{Mapper} #{path}"
        end

        def defaults
          {
            path: Path.new,
            logger: Logger.new(Aux::NullStream::INSTANCE),
            strict: true,
            # Unstable feature, most likely it's name will change
            include_sensitive_attributes: false
          }
        end

        # Creates new context, resembling traversal to specified segment
        #
        # @param [AMA::Entity::Mapper::Path::Segment, String, Symbol] segment
        # @return [AMA::Entity::Mapper::Context]
        def advance(segment)
          return self if segment.nil?
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
