# require 'bundler'
# puts File.absolute_path('Gemfile', Dir.pwd)
# Bundler.read_file(File.absolute_path('Gemfile', Dir.pwd))
#
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
    GettextSetup.config['source_files'].map do |p|
      Dir.glob(p)
    end.flatten
  end

  def pot_file_path
    File.join(locale_path, GettextSetup.config['project_name'] + ".pot")
  end

  desc "Update pot files"
  task :pot do
    package_name = GettextSetup.config['package_name']
    project_name = GettextSetup.config['project_name']
    bugs_address = GettextSetup.config['bugs_address']
    copyright_holder = GettextSetup.config['copyright_holder']
    version=`git describe`
    system("rxgettext -o locales/#{project_name}.pot --no-wrap --sort-by-file " +
           "--no-location --add-comments --msgid-bugs-address '#{bugs_address}' " +
           "--package-name '#{package_name}' " +
           "--package-version '#{version}' " +
           "--copyright-holder='#{copyright_holder}' --copyright-year=#{Time.now.year} " +
           "#{files_to_translate.join(" ")}")
    puts "POT file locales/#{project_name}.pot has been updated"
  end

  desc "Update po file for a specific language"
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
