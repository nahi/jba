# -*- encoding: utf-8 -*-
require File.expand_path('../lib/jba/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Hiroshi Nakamura"]
  gem.email         = ["nahi@ruby-lang.org"]
  gem.description   = %q{JBA file format handler}
  gem.summary       = %q{For now it only can generate General Transfer file}
  gem.homepage      = ""

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'test-unit'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "jba"
  gem.require_paths = ["lib"]
  gem.version       = Jba::VERSION
end
