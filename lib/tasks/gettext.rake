# -*- encoding: utf-8 -*-

require_relative '../gettext-setup/gettext_setup'
require_relative '../gettext-setup/pot'
require_relative '../gettext-setup/metadata_pot'
require_relative '../string_prep/ruby_wrapper'

namespace :gettext do
  desc 'Generate a new POT file and replace old if strings changed'

  task :update_pot do
    begin
      result = GettextSetup::Pot.update_pot
      exit 1 unless result
    rescue GettextSetup::NoConfigFoundError => e
      puts e.message
      exit 1
    end
  end

  desc 'Generate POT file'
  task :pot do
    begin
      result = GettextSetup::Pot.generate_new_pot
      if result
        puts "POT file #{GettextSetup::Pot.pot_file_path} has been generated"
      else
        exit 1
      end
    rescue GettextSetup::NoConfigFoundError => e
      puts e.message
    end
  end

  desc 'Generate POT file for metadata'
  task :metadata_pot do
    begin
      result = GettextSetup::MetadataPot.generate_metadata_pot
      if result
        puts "POT metadata file #{GettextSetup::MetadataPot.metadata_path} has been generated"
      else
        exit 1
      end
    rescue GettextSetup::NoConfigFoundError => e
      puts e.message
    end
  end

  desc "Run string wrapper against all Ruby files in a module"
  task :wrap_ruby_string do
    begin
      dir = GettextSetup.config['project_name']
      exec("../string_prep/ruby_wrapper.rb #{dir}")
    end
  end


  desc 'Update PO file for a specific language'
  task :po, [:language] do |_, args|
    begin
      result = GettextSetup::Pot.generate_new_po(args.language)
      exit 1 unless result
    rescue GettextSetup::NoConfigFoundError => e
      puts e.message
    end
  end
end
