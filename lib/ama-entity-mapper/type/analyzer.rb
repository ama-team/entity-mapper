# frozen_string_literal: true

require_relative '../type'
require_relative 'any'

module AMA
  module Entity
    class Mapper
      class Type
        # Some naive automatic attribute discovery
        class Analyzer
          # @param [Class, Module] klass
          # @return [AMA::Entity::Mapper:Type]
          def self.analyze(klass)
            type = Type.new(klass)
            writers = klass.instance_methods.grep(/\w+=$/)
            writers.map do |writer|
              attribute = writer[0..-2]
              type.attribute!(attribute, Type::Any::INSTANCE, nullable: true)
            end
            type
          end
        end
      end
    end
  end
end
