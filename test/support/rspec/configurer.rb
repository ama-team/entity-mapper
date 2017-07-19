# frozen_string_literal: true

require 'rspec'
require 'allure-rspec'
require 'coveralls'

module AMA
  module Entity
    class Mapper
      module Test
        module RSpec
          class Configurer
            class << self
              def configure(test_type)
                configure_coverage(test_type)
                ::RSpec.configure do |config|
                  # Enable flags like --only-failures and --next-failure
                  path = 'test/metadata/rspec/status'
                  config.example_status_persistence_file_path = path

                  config.expect_with :rspec do |c|
                    c.syntax = :expect
                  end

                  configure_allure(config, test_type)

                  yield(config) if block_given?
                end
              end

              private

              def root
                (0..2).reduce(__dir__) { |dir| ::File.dirname(dir) }
              end

              def metadata_path(*names)
                ::File.join(root, 'test', 'metadata', *names.map(&:to_s))
              end

              def configure_coverage(test_type)
                target_dir = metadata_path('coverage')
                ::Coveralls.wear_merged! do
                  add_filter 'test'
                  coverage_dir target_dir
                  command_name "rspec:#{test_type}"
                  self.formatters = [
                    ::SimpleCov::Formatter::SimpleFormatter,
                    ::SimpleCov::Formatter::HTMLFormatter,
                    ::Coveralls::SimpleCov::Formatter
                  ]
                end
              end

              def configure_allure(rspec_config, test_type)
                rspec_config.include ::AllureRSpec::Adaptor
                ::AllureRSpec.configure do |allure|
                  allure.output_dir = metadata_path('allure', test_type)
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
