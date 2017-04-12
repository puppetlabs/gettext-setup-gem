require 'bundler/setup'
require 'rake'

require_relative './lib/gettext-setup/gettext_setup.rb'

import 'lib/tasks/gettext.rake'

namespace :bundler do
  task :setup do
    require 'bundler/setup'
  end
end

desc 'Update i18n POT translations'
task :spec_regen do
  %w(spec_locales fixture_locales locales).each do |locale|
    locale_path = File.join(File.dirname(__FILE__), 'spec', 'fixtures', locale)
    puts "-> Checking #{locale_path}"
    GettextSetup.initialize(locale_path)
    GettextSetup::Pot.update_pot
  end
end

if defined?(RSpec::Core::RakeTask)
  namespace :spec do
    require 'rspec/core'
    require 'rspec/core/rake_task'
    puts 'running'

    desc 'Run all specs.'
    RSpec::Core::RakeTask.new(all: 'bundler:setup') do |t|
      puts "iterating: #{t}"
      t.pattern = 'spec/**/*_spec.rb'
    end
  end
end
