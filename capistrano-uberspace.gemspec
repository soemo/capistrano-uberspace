# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/uberspace/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Jan Schulz-Hofen", "Martin Meyerhoff", "Sören Mothes"]
  gem.license       = 'MIT'
  gem.email         = ["soeren.mothes@gmail.com"]
  gem.description   = %q{Capistrano 3 tasks to deploy to Uberspace}
  gem.summary       = %q{Capistrano::Uberspace helps you deploy a Ruby on Rails app on Uberspace, a popular German shared hosting provider.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "capistrano-uberspace"
  gem.require_paths = ["lib"]
  gem.version       = Capistrano::Uberspace::VERSION

  # dependencies for capistrano
  gem.add_dependency 'capistrano', '~> 3.1'
  gem.add_dependency 'capistrano-bundler', '>= 1.1', '< 3'
  gem.add_dependency 'capistrano-secrets-yml', '~> 1.0.0'

  # dependencies for passenger on Uberspace
  gem.add_dependency 'passenger-rails'

  # dependency for mysql on Uberspace
  gem.add_dependency 'mysql2',            '>=0.3.11'

end
