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
          # @!attribute default
          #   @return [Object]
          attr_accessor :default

          def initialize(owner, name, *types, **options)
            @owner = validate_owner!(owner)
            @name = validate_name!(name)
            @types = validate_types!(types)
            @sensitive = options.fetch(:sensitive, false)
            @virtual = options.fetch(:virtual, false)
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
            message = "Attribute #{owner.type}.#{name}"
            return message unless virtual
            "#{message} (virtual)"
          end

          private

          def validate_owner!(owner)
            return owner if owner.is_a?(Type)
            message = 'Provided owner has to be a Type instance,' \
              " #{owner.class} received"
            compliance_error(message)
          end

          def validate_name!(name)
            return name if name.is_a?(Symbol)
            message = "Provided name has to be Symbol, #{name.class} received"
            compliance_error(message)
          end

          def validate_types!(types)
            compliance_error("No types provided for #{self}") if types.empty?
            types.each do |type|
              next if type.is_a?(Type)
              message = 'Provided type has to be a Type instance, ' \
                "#{type.class} received"
              compliance_error(message)
            end
          end
        end
      end
    end
  end
end
