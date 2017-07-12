# frozen_String_literal: true

module AMA
  module Entity
    class Mapper
      class Type
        # Stores data about single type attribute
        class Attribute
          # @!attribute
          #   @return [AMA::Entity::Mapper::Type::Concrete]
          attr_accessor :owner
          # @!attribute
          #   @return [Symbol]
          attr_accessor :name
          # @!attribute types List of possible types attribute may take
          #   @return [Array<AMA::Entity::Mapper::Type>]
          attr_accessor :types
          # @!attribute virtual
          #   @return [TrueClass, FalseClass]
          attr_accessor :virtual
          # @!attribute sensitive
          #   @return [TrueClass, FalseClass]
          attr_accessor :sensitive
          # @!attribute nullable
          #   @return [TrueClass, FalseClass]
          attr_accessor :nullable
          # @!attribute values Possible values this attribute can take
          #   @return [Array]
          attr_accessor :values
          # @!attribute validator Ruby block that validates resulting value
          #   @return [Proc]
          attr_accessor :validator

          def initialize(owner, name, *types, **options)
            @owner = owner
            @name = name
            @types = types
            @nullable = options.fetch(:nullable, true)
            @sensitive = options.fetch(:sensitive, false)
            @virtual = options.fetch(:virtual, false)
          end

          def hash
            @owner.hash ^ @name.hash
          end

          def eql?(other)
            return false unless other.is_a?(self.class)
            @owner == other.owner && @name == other.name
          end

          def ==(other)
            eql?(other)
          end

          def to_s
            "Attribute :#{name} (#{owner})"
          end
        end
      end
    end
  end
end
