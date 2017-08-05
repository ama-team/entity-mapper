# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
# rubocop:disable Metrics/BlockLength

require 'yaml'
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
    task type do
      Rake::Task[:'test:clean'].invoke
      types.each do |stage|
        Rake::Task[:"test:#{stage}:only"].invoke
        break if stage == type
      end
    end
    namespace type do
      RSpec::Core::RakeTask.new(:only).tap do |task|
        task.pattern = "suite/#{type}/**/*.spec.rb"
        task.rspec_opts = "--default-path test --require support/rspec/#{type}/config"
      end
      task :'with-report' do
        Rake::Task[:'test:clean'].invoke
        begin
          Rake::Task[:"test:#{type}"].invoke
        ensure
          Rake::Task[:'test:report'].invoke
        end
      end
      namespace :only do
        task :'with-report' do
          Rake::Task[:'test:clean'].invoke
          begin
            Rake::Task[:"test:#{type}:only"].invoke
          ensure
            Rake::Task[:'test:report'].invoke
          end
        end
      end
    end
  end

  task all: %i[acceptance]

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

task :gemspec do
  spec = ::Gem::Specification.load("#{__dir__}/ama-entity-mapper.gemspec")
  puts spec.to_yaml
end

task :jekyll do
  sh 'bundle exec jekyll serve -s docs/ -d docs/_site/ --baseurl /ruby-entity-mapper'
end

task :default do
  sh 'bundle exec rake -AT'
end
