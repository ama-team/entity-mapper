# frozen_string_literal: true
# coding: utf-8

# rubocop:disable Metrics/LineLength

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'ama-entity-mapper'
  spec.version       = '0.1.0'
  spec.authors       = ['AMA Team']
  spec.email         = ['dev@amagroup.ru']

  spec.summary       = 'Converts and instantiates classes from native data structures'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/ama-team/ruby-entity-mapper'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = []
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'rubocop', '~> 0.49'
  spec.add_development_dependency 'allure-rspec', '~> 0.8.0'
end
