# frozen_string_literal: true

require_relative '../mixin/errors'

module AMA
  module Entity
    class Mapper
      class Type
        # Stores data about single type attribute
        class Attribute
          include Mixin::Errors

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

          def initialize(owner, name, *types, **options)
            @owner = owner
            @name = name
            @types = types
            @sensitive = options.fetch(:sensitive, false)
            @virtual = options.fetch(:virtual, false)
          end

          def extract(object)
            applicable_to!(object)
            return object.send(@name) if object.respond_to?(@name)
            object.instance_variable_get("@#{@name}")
          end

          def set(object, value)
            applicable_to!(object)
            method = "#{name}="
            return object.send(method, value) if object.respond_to?(method)
            object.instance_variable_set("@#{@name}", value)
          end

          def satisfied_by?(value)
            @types.any? { |type| type.satisfied_by?(value) }
          end

          def resolved?
            types.all?(&:resolved?)
          end

          def resolved!(context = nil)
            types.each do |type|
              type.resolved!(context)
            end
          end

          # @param [AMA::Entity::Mapper::Type] parameter
          # @param [AMA::Entity::Mapper::Type] substitution
          # @return [AMA::Entity::Mapper::Type::Attribute]
          def resolve_parameter(parameter, substitution)
            clone.tap do |clone|
              clone.types = types.map do |type|
                next substitution if type == parameter
                type.resolve_parameter(parameter, substitution)
              end
            end
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
            "Attribute #{owner.type}.#{name}"
          end

          private

          def applicable_to!(object)
            return if @owner.instance?(object)
            message = "Can't extract attribute #{@name} " \
              "from #{object.class}, expected #{@owner}"
            compliance_error(message)
          end

          def validate_owner!(owner)
            require_relative 'concrete'
            return owner if owner.is_a?(Concrete)
            message = 'Provided owner has to be a Concrete Type instance,' \
              " #{owner.class} received"
            compliance_error(message)
          end

          def validate_name!(name)
            return name if name.is_a?(Symbol)
            message = "Provided name has to be Symbol, #{name.class} received"
            compliance_error(message)
          end
        end
      end
    end
  end
end
