# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

require 'yaml'
require 'rspec'
require 'allure-rspec'
require 'coveralls'
require 'tempfile'

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

                  setup_context(config)

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
                sources = sources_pattern
                ::Coveralls.wear_merged! do
                  add_filter 'test'
                  add_filter 'lib/mapper/version'
                  coverage_dir target_dir
                  command_name "rspec:#{test_type}"
                  self.formatters = [
                    ::SimpleCov::Formatter::SimpleFormatter,
                    ::SimpleCov::Formatter::HTMLFormatter,
                    ::Coveralls::SimpleCov::Formatter
                  ]
                  track_files sources
                end
                # requiring every source file explicitly so
                # SimpleCov would report correct relevant line size
                require_sources
              end

              def sources_pattern
                ::File.join(root, 'lib', '**', '*.rb')
              end

              def require_sources
                Dir.glob(sources_pattern).each do |file|
                  require(file)
                end
              end

              def configure_allure(rspec_config, test_type)
                rspec_config.include ::AllureRSpec::Adaptor
                ::AllureRSpec.configure do |allure|
                  allure.output_dir = metadata_path('allure', test_type)
                  allure.logging_level = Logger::INFO
                end
                add_allure_helper_method
              end

              def add_allure_helper_method
                ::AllureRSpec::DSL::Example.instance_eval do
                  define_method :attach_yaml do |data, name = 'data'|
                    file = Tempfile.new('ama-entity-mapper-')
                    begin
                      file.write(data.to_yaml)
                      file.close
                      attach_file("#{name}.yml", file, mime_type: 'text/plain')
                    ensure
                      file.unlink
                    end
                  end
                end
              end

              def setup_context(config)
                config.include(shared_module)
                config.after(:each) do |example|
                  ::AMA::Entity::Mapper.engine = nil
                  begin
                    unless logger_io.size.zero?
                      options = { mime_type: 'text/plain' }
                      example.attach_file('output.log', logger_io, **options)
                    end
                  rescue StandardError => e
                    puts "Unexpected error while saving Allure attachment: #{e}"
                  ensure
                    logger_io.close(true)
                  end
                end
              end

              def shared_module
                Module.new do
                  def self.included(example_group)
                    example_group.let(:logger_io) do
                      Tempfile.new('ama-entity-mapper-')
                    end
                    example_group.let(:logger) do
                      Logger.new(logger_io)
                    end
                    example_group.let(:ctx) do
                      ctx = double(path: nil, logger: logger)
                      allow(ctx).to receive(:advance).and_return(ctx)
                      ctx
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
