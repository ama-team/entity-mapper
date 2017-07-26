# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# rubocop:disable Metrics/BlockLength

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'fileutils'

namespace :test do
  task :clean do
    %w[metadata report].each do |directory|
      FileUtils.rm_rf(::File.join(__dir__, 'test', directory))
    end
  end

  task :report do
    sh 'allure generate --clean -o test/report/allure test/metadata/allure/**'
  end

  types = %i[unit integration acceptance]
  types.each do |type|
    RSpec::Core::RakeTask.new(type).tap do |task|
      task.pattern = "suite/#{type}/**/*.spec.rb"
      task.rspec_opts = "--default-path test --require support/rspec/#{type}/config"
    end
    namespace type do
      task :'with-report' do
        Rake::Task[:'test:clean'].invoke
        begin
          types.each do |stage|
            Rake::Task[:"test:#{stage}"].invoke
            break if stage == type
          end
        ensure
          Rake::Task[:'test:report'].invoke
        end
      end
      namespace :only do
        task :'with-report' do
          Rake::Task[:'test:clean'].invoke
          begin
            Rake::Task[:"test:#{type}"].invoke
          ensure
            Rake::Task[:'test:report'].invoke
          end
        end
      end
    end
  end

  task all: %i[unit integration acceptance]

  task :'with-report' do
    Rake::Task[:'test:clean'].invoke
    begin
      Rake::Task[:'test:all'].invoke
    ensure
      Rake::Task[:'test:report'].invoke
    end
  end
end

task test: %i[test:all]

namespace :lint do
  RuboCop::RakeTask.new(:rubocop)

  task all: %i[rubocop]
end

task lint: %i[lint:all]

task validate: %i[lint test:with-report]

task :default do
  sh 'bundle exec rake -AT'
end
