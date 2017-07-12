# frozen_string_literal: true

require_relative '../type'

module AMA
  module Entity
    class Mapper
      class Type
        # A reference for parameter defined in particular type
        # Acts as a proxy, delegating method calls to whatever lies as specified
        # parameter in owner
        class Parameter < Type
          attr_reader :owner
          attr_reader :id

          # @param [AMA::Entity::Mapper::Type] owner
          # @param [Symbol] id
          def initialize(owner, id)
            @owner = owner
            @id = id
          end

          def to_s
            "Parameter (reference) type for variable type :#{id} " \
              "(declared in #{owner})"
          end

          def hash
            @owner.hash ^ @id.hash
          end

          def eql?(other)
            return false unless other.is_a?(self.class)
            @owner == other.owner && @id == other.id
          end

          Type.instance_methods.each do |method|
            next if method_defined?(method)
            define_method(method) do |*args|
              @owner.parameters[@id].send(method, *args)
            end
          end
        end
      end
    end
  end
end
