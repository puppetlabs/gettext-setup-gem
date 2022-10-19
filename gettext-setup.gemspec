# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'gettext-setup'
  spec.version       = `git describe --tags`.tr('-', '.').chomp
  spec.authors       = ['Puppet']
  spec.email         = ['info@puppet.com']
  spec.description   = 'A gem to ease i18n'
  spec.summary       = 'A gem to ease internationalization with fast_gettext'
  spec.homepage      = 'https://github.com/puppetlabs/gettext-setup-gem'
  spec.license       = 'Apache-2.0'

  spec.files         = Dir['{lib,locales,spec}/**/*', 'LICENSE', 'README.md']
  spec.test_files    = Dir['spec/**/*']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.5.0'

  spec.add_dependency 'fast_gettext', '~> 2.1'
  spec.add_dependency 'gettext', '~> 3.4'
  spec.add_dependency 'locale'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'rspec-core', '~> 3.1'
  spec.add_development_dependency 'rspec-expectations', '~> 3.1'
  spec.add_development_dependency 'rspec-mocks', '~> 3.1'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
end
