# require 'bundler'
# puts File.absolute_path('Gemfile', Dir.pwd)
# Bundler.read_file(File.absolute_path('Gemfile', Dir.pwd))
#
require_relative '../gettext-setup/gettext_setup'
require_relative 'task_helper.rb'
require_relative '../metadata_pot/metadata_pot'
#
# GettextSetup.initialize(File.absolute_path('locales', Dir.pwd))

namespace :gettext do
  desc 'Generate a new POT file and replace old if strings changed'
  task :update_pot do
    if !File.exist? pot_file_path
      puts 'No existing POT file, generating new'
      generate_new_pot
    else
      old_pot = pot_file_path + '.old'
      File.rename(pot_file_path, old_pot)
      generate_new_pot
      if string_changes?(old_pot, pot_file_path)
        File.delete(old_pot)
        puts 'String changes detected, replacing with updated POT file'
      else
        puts 'No string changes detected, keeping old POT file'
        File.rename(old_pot, pot_file_path)
      end
    end
  end

  desc 'Generate POT file'
  task :pot do
    generate_new_pot
    puts "POT file #{pot_file_path} has been generated"
  end

  desc 'Generate POT file for metadata'
  task :generate_metadata_pot do
    generate_new_pot_metadata
    puts "POT file #{metadata_pot_file_path} has been generated"
  end

  desc 'Update PO file for a specific language'
  task :po, [:language] do |_, args|
    language = args.language || ENV['LANGUAGE']

    # Let's do some pre-verification of the environment.
    if language.nil?
      puts "You need to specify the language to add. Either 'LANGUAGE=eo rake gettext:po' or 'rake gettext:po[LANGUAGE]'"
      next
    end

    language_path = File.join(locale_path, language)
    mkdir_p(language_path)

    po_file_path = File.join(language_path,
                             GettextSetup.config['project_name'] + '.po')
    if File.exist?(po_file_path)
      system("msgmerge -U #{po_file_path} #{pot_file_path}")
    else
      system("msginit --no-translator -l #{language} -o #{po_file_path} -i #{pot_file_path}")
    end
  end
end
