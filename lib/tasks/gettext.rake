# -*- encoding: utf-8 -*-

# require 'bundler'

require_relative '../gettext-setup/gettext_setup'
require_relative '../gettext-setup/pot'
require_relative '../gettext-setup/metadata_pot'

namespace :gettext do
  desc 'Generate a new POT file and replace old if strings changed'

  task :update_pot do
    path = GettextSetup::Pot.pot_file_path
    if !File.exist? path
      puts 'No existing POT file, generating new'
      GettextSetup::Pot.generate_new_pot
    else
      old_pot = path + '.old'
      File.rename(path, old_pot)
      GettextSetup::Pot.generate_new_pot
      if GettextSetup::Pot.string_changes?(old_pot, path)
        File.delete(old_pot)
        puts 'String changes detected, replacing with updated POT file'
      else
        puts 'No string changes detected, keeping old POT file'
        File.rename(old_pot, path)
      end
    end
  end

  desc 'Generate POT file'
  task :pot do
    GettextSetup::Pot.generate_new_pot
    puts "POT file #{GettextSetup::Pot.pot_file_path} has been generated"
  end

  desc 'Generate POT file for metadata'
  task :generate_metadata_pot do
    GettextSetup::MetadataPot.generate_metadata_pot
    puts "POT metadata file #{GettextSetup::MetadataPot.metadata_path} has been generated"
  end

  desc 'Update PO file for a specific language'
  task :po, [:language] do |_, args|
    path = GettextSetup::Pot.pot_file_path
    language = args.language || ENV['LANGUAGE']

    # Let's do some pre-verification of the environment.
    if language.nil?
      puts "You need to specify the language to add. Either 'LANGUAGE=eo rake gettext:po' or 'rake gettext:po[LANGUAGE]'"
      next
    end

    language_path = File.join(GettextSetup::Pot.locale_path, language)
    mkdir_p(language_path)

    po_file_path = File.join(language_path,
                             GettextSetup.config['project_name'] + '.po')
    if File.exist?(po_file_path)
      system("msgmerge -U #{po_file_path} #{path}")
    else
      system("msginit --no-translator -l #{language} -o #{po_file_path} -i #{path}")
    end
  end
end
