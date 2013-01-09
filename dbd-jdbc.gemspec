# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dbd/jdbc/version'

Gem::Specification.new do |gem|
  gem.name              = "dbd-jdbc"
  gem.version           = DBI::DBD::Jdbc::VERSION
  gem.authors           = ["Chad Johnson"]
  gem.email             = ["chad.j.johnson@gmail.com"]
  gem.description       = %q{A JDBC DBD driver for Ruby DBI}
  gem.summary           = %q{JDBC driver for DBI, originally by Kristopher Schmidt and Ola Bini}
  gem.homepage          = "http://github.com/chadj/dbd-jdbc"
  gem.rubyforge_project = 'jruby-extras'
  gem.platform          = Gem::Platform::JAVA
  gem.files             = `git ls-files`.split($/)
  gem.require_paths     = ["lib"]

  gem.add_development_dependency 'rake'

  # Not adding dbi as a hard dependency, since either the "real" dbi gem
  # or rails-dbi will work.
  gem.requirements << 'dbi or ruby-dbi gem'
end
