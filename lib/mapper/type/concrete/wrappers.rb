# frozen_string_literal: true

require_relative '../../mixin/errors'

module AMA
  module Entity
    class Mapper
      class Type
        class Concrete
          # This module contains wrappers for user-supplied procs that would
          # provide slightly more descriptive messages than simple errors.
          module Wrappers
            class << self
              include Mixin::Errors

              def factory(type, factory)
                handle = factory.method(:create)
                emitter = self
                wrapper = lambda do |context = nil, data = nil|
                  begin
                    handle.call(context, data)
                  rescue StandardError => e
                    message = "Failed to instantiate type #{type} using factory"
                    if e.is_a?(ArgumentError)
                      message += '. Does provided factory conform to ' \
                        'lambda(context = nil, data = nil) interface?'
                    end
                    emitter.mapping_error(message, context: context, parent: e)
                  end
                end
                install_method(factory, :create, wrapper)
              end

              def enumerator(proc)
                lambda do |object, type, context = nil|
                  begin
                    proc.call(object, type, context)
                  rescue ArgumentError => e
                    message = "Failed to create enumerator for type #{type}"
                    if e.is_a?(StandardError)
                      message += '. Does enumerator factory conform to ' \
                        'lambda(object, type, context = nil) interface?'
                    end
                    mapping_error(message, context: context, parent: e)
                  end
                end
              end

              def acceptor(proc)
                lambda do |object, type, context = nil|
                  begin
                    proc.call(object, type, context)
                  rescue ArgumentError => e
                    message = "Failed to create acceptor for type #{type}"
                    if e.is_a?(StandardError)
                      message += '. Does acceptor factory conform to ' \
                        'lambda(object, type, context = nil) interface?'
                    end
                    mapping_error(message, context: context, parent: e)
                  end
                end
              end

              def extractor(extractor_factory)
                lambda do |object, type, context = nil|
                  begin
                    extractor_factory.call(object, type, context)
                  rescue ArgumentError => e
                    message = "Failed to create extractor for type #{type}"
                    if e.is_a?(StandardError)
                      message += '. Does extractor factory conform to ' \
                        'lambda(object, context = nil) interface?'
                    end
                    mapping_error(message, context: context, parent: e)
                  end
                end
              end

              private

              def install_method(object, method, handler)
                object.define_singleton_method(method, handler)
                object
              end
            end
          end
        end
      end
    end
  end
end
