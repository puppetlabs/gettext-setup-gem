# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "gettext-setup"
  spec.version       = "0.2"
  spec.authors       = ["Puppet"]
  spec.email         = ["info@puppet.com"]
  spec.description   = "A gem to ease i18n"
  spec.summary       = "A gem to ease internationalization with fast_gettext"
  spec.homepage      = "https://github.com/puppetlabs/gettext-setup-gem"
  spec.license       = "ASL2"

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
