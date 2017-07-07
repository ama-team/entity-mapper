# frozen_string_literal: true

require 'rspec'
require 'allure-rspec'
require 'coveralls'

module AMA
  module Entity
    module Mapper
      module Test
        module RSpec
          class Configurator
            class << self
              def configure(test_type)
                Coveralls.wear!
                ::RSpec.configure do |config|
                  # Enable flags like --only-failures and --next-failure
                  config.example_status_persistence_file_path = '.rspec_status'

                  config.expect_with :rspec do |c|
                    c.syntax = :expect
                  end

                  configure_allure(config, test_type)

                  yield(config) if block_given?
                end
              end

              private

              def configure_allure(rspec_config, test_type)
                rspec_config.include ::AllureRSpec::Adaptor
                ::AllureRSpec.configure do |allure|
                  allure.output_dir = "test/metadata/allure/#{test_type}"
                  allure.logging_level = Logger::INFO
                end
              end
            end
          end
        end
      end
    end
  end
end
