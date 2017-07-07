# frozen_String_literal: true

module AMA
  module Entity
    class Mapper
      # Stores data about single type attribute
      class Attribute
        # @!attribute
        #   @return [AMA::Entity::Mapper::Type::Concrete]
        attr_accessor :owner
        # @!attribute
        #   @return [Symbol]
        attr_accessor :name
        # @!attribute type
        #   @return [AMA::Entity::Mapper::Type::Proxy]
        attr_accessor :type
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

        def initialize(owner, name, type, **options)
          @owner = owner
          @name = name
          @type = type
          @nullable = options.fetch(:nullable, true)
          @sensitive = options.fetch(:sensitive, false)
          @virtual = options.fetch(:virtual, false)
        end
      end
    end
  end
end
