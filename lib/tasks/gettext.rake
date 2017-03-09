# require 'bundler'
# puts File.absolute_path('Gemfile', Dir.pwd)
# Bundler.read_file(File.absolute_path('Gemfile', Dir.pwd))
#
require 'open3'
require_relative '../gettext-setup/gettext_setup'
#
# GettextSetup.initialize(File.absolute_path('locales', Dir.pwd))

namespace :gettext do

  def locale_path
    GettextSetup.locales_path
  end

  def text_domain
    FastGettext.text_domain
  end

  def files_to_translate
    files = GettextSetup.config['source_files'].map do |p|
      Dir.glob(p)
    end.flatten
    # check for optional list of files to exclude from string
    # extraction
    exclusions = (GettextSetup.config['exclude_files'] || []).map do |p|
      Dir.glob(p)
    end.flatten
    files - exclusions
  end

  def pot_file_path
    File.join(locale_path, GettextSetup.config['project_name'] + ".pot")
  end

  def generate_new_pot
    config = GettextSetup.config
    package_name = config['package_name']
    project_name = config['project_name']
    bugs_address = config['bugs_address']
    copyright_holder = config['copyright_holder']
    # Done this way to allow the user to enter an empty string in the config.
    if config.has_key?('comments_tag')
      comments_tag = config['comments_tag']
    else
      comments_tag = 'TRANSLATORS'
    end
    version=`git describe`
    system("rxgettext -o locales/#{project_name}.pot --no-wrap --sort-by-file " +
           "--no-location --add-comments#{comments_tag.to_s == '' ? '' : '=' + comments_tag} --msgid-bugs-address '#{bugs_address}' " +
           "--package-name '#{package_name}' " +
           "--package-version '#{version}' " +
           "--copyright-holder='#{copyright_holder}' --copyright-year=#{Time.now.year} " +
           "#{files_to_translate.join(" ")}")
  end

  desc "Generate a new POT file and replace old if strings changed"
  task :update_pot do
    if !File.exists? pot_file_path
      puts "No existing POT file, generating new"
      generate_new_pot
    else
      old_pot = pot_file_path + ".old"
      File.rename(pot_file_path, old_pot)
      generate_new_pot
      stdout, stderr, status = Open3.capture3("msgcmp --use-untranslated '#{old_pot}' '#{pot_file_path}'")
      if status == 1 || /this message is not used/.match(stderr)
        File.delete(old_pot)
        puts "String changes detected, replacing with updated POT file"
      else
        puts "No string changes detected, keeping old POT file"
        File.rename(old_pot, pot_file_path)
      end
    end
  end

  desc "Generate POT file"
  task :pot do
    generate_new_pot
    puts "POT file #{pot_file_path} has been generated"
  end

  desc "Update PO file for a specific language"
  task :po, [:language] do |_, args|
    language = args.language || ENV["LANGUAGE"]

    # Let's do some pre-verification of the environment.
    if language.nil?
      puts "You need to specify the language to add. Either 'LANGUAGE=eo rake gettext:po' or 'rake gettext:po[LANGUAGE]'"
      next
    end

    language_path = File.join(locale_path, language)
    mkdir_p(language_path)

    po_file_path = File.join(language_path,
                             GettextSetup.config['project_name'] + ".po")
    if File.exists?(po_file_path)
      system("msgmerge -U #{po_file_path} #{pot_file_path}")
    else
      system("msginit --no-translator -l #{language} -o #{po_file_path} -i #{pot_file_path}")
    end
  end
end
