require 'bundler/setup'
require 'rake'

require_relative './lib/gettext-setup/gettext_setup.rb'

import 'lib/tasks/gettext.rake'

namespace :bundler do
  task :setup do
    require 'bundler/setup'
  end
end

desc "Update i18n POT translations"
task :"spec-regen" do
  require 'rake'
  GettextSetup.initialize(File.absolute_path(File.join('spec', 'fixtures', 'locales'), File.dirname(__FILE__)))
  Dir.chdir('spec/fixtures')
  Rake.application['gettext:pot'].invoke
  # No use in running these without Transifex integration to actually translate
  # strings.
  # Rake.application['gettext:po'].invoke('de')
end

if defined?(RSpec::Core::RakeTask)
  namespace :spec do
    require 'rspec/core'
    require 'rspec/core/rake_task'
    puts 'running'

    desc 'Run all specs.'
    RSpec::Core::RakeTask.new(:all => :"bundler:setup") do |t|
      puts "iterating: #{t}"
      t.pattern = 'spec/**/*_spec.rb'
    end
  end
end
