# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "gettext-setup"
  spec.version       = "0.12"
  spec.authors       = ["Puppet"]
  spec.email         = ["info@puppet.com"]
  spec.description   = "A gem to ease i18n"
  spec.summary       = "A gem to ease internationalization with fast_gettext"
  spec.homepage      = "https://github.com/puppetlabs/gettext-setup-gem"
  spec.license       = "Apache-2.0"

  spec.files         = Dir["{lib,locales,spec}/**/*", "LICENSE", "README.md"]
  spec.test_files    = Dir["spec/**/*"]
  spec.require_paths = ["lib"]

  spec.add_dependency "gettext", ">= 3.0.2"
  spec.add_dependency "fast_gettext", "~> 1.1.0"
  spec.add_dependency "locale"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", "~> 3.1"
  spec.add_development_dependency "rspec-core", "~> 3.1"
  spec.add_development_dependency "rspec-expectations", "~> 3.1"
  spec.add_development_dependency "rspec-mocks", "~> 3.1"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "webmock"

end
