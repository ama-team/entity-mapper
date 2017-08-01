# frozen_string_literal: true

require_relative 'reflection'

module AMA
  module Entity
    class Mapper
      module Mixin
        # This module provides Type and Attribute classes with shortcut
        # handler :name, :method method to register handlers
        module HandlerSupport
          class << self
            def included(klass)
              declare_namespace_method(klass)
              declare_handler_method(klass)
            end

            def declare_namespace_method(klass)
              klass.define_singleton_method(:handler_namespace) do |namespace|
                @handler_namespace = namespace
              end
            end

            def declare_handler_method(klass)
              processor = self
              klass.define_singleton_method(:handler) do |key, method|
                handler_name = key.capitalize
                handler_class = @handler_namespace.const_get(handler_name)
                processor.declare_handler_getter(klass, key, handler_class)
                processor.declare_handler_setter(klass, key, handler_class)
                processor.declare_handler_block_setter(klass, key, method)
              end
            end

            def declare_handler_getter(klass, handler_key, handler_class)
              instance = handler_class::INSTANCE
              klass.instance_eval do
                define_method(handler_key) do
                  instance_variable_get("@#{handler_key}") || instance
                end
              end
            end

            def declare_handler_setter(klass, handler_key, handler_class)
              klass.instance_eval do
                define_method("#{handler_key}=") do |handler|
                  unless handler.class == handler_class
                    handler = handler_class.wrap(handler)
                  end
                  instance_variable_set("@#{handler_key}", handler)
                  self
                end
              end
            end

            def declare_handler_block_setter(klass, handler_key, method)
              klass.instance_eval do
                include Mixin::Reflection
                define_method("#{handler_key}_block") do |&block|
                  send("#{handler_key}=", method_object(method, &block))
                end
              end
            end
          end
        end
      end
    end
  end
end
