# -*- encoding: utf-8 -*-

require 'open3'
require 'English'

module GettextSetup
  module Pot
    def self.text_domain
      FastGettext.text_domain
    end

    def self.files_to_translate
      files = (GettextSetup.config['source_files'] || []).map do |p|
        Dir.glob(p)
      end.flatten
      # check for optional list of files to exclude from string
      # extraction
      exclusions = (GettextSetup.config['exclude_files'] || []).map do |p|
        Dir.glob(p)
      end.flatten

      # if file is a directory, take it out of the array. directories
      # cause rxgettext to error out.
      (files - exclusions).reject { |file| File.directory?(file) }
    end

    def self.pot_file_path
      return if GettextSetup.locales_path.nil?
      return if GettextSetup.config['project_name'].nil?
      File.join(GettextSetup.locales_path, GettextSetup.config['project_name'] + '.pot')
    end

    def self.po_file_path(language)
      return if GettextSetup.locales_path.nil?
      return if GettextSetup.config['project_name'].nil?
      return if language.nil?
      File.join(GettextSetup.locales_path, language, GettextSetup.config['project_name'] + '.po')
    end

    def self.string_changes?(old_pot, new_pot)
      # Warnings will be in another language if locale is not set to en_US
      _, stderr, status = Open3.capture3("LANG=en_US msgcmp --use-untranslated '#{old_pot}' '#{new_pot}'")
      if status.exitstatus == 1 || /this message is not used/.match(stderr) || /this message is used but not defined/.match(stderr)
        return true
      end
      return false
    rescue IOError
      # probably means msgcmp is not present on the system
      # so return true to be on the safe side
      return true
    end

    def self.generate_new_pot(locales_path = GettextSetup.locales_path, path = nil)
      GettextSetup.initialize(locales_path)
      path ||= pot_file_path
      config = GettextSetup.config
      package_name = config['package_name']
      bugs_address = config['bugs_address']
      copyright_holder = config['copyright_holder']
      # Done this way to allow the user to enter an empty string in the config.
      comments_tag = config.key?('comments_tag') ? config['comments_tag'] : 'TRANSLATORS'
      version = `git describe`
      system("rxgettext -o #{path} --no-wrap --sort-by-file " \
             "--add-comments#{comments_tag.to_s == '' ? '' : '=' + comments_tag} --msgid-bugs-address '#{bugs_address}' " \
             "--package-name '#{package_name}' " \
             "--package-version '#{version}' " \
             "--copyright-holder='#{copyright_holder}' --copyright-year=#{Time.now.year} " +
             files_to_translate.join(' '))
      $CHILD_STATUS.success?
    end

    def self.generate_new_po(language, locales_path = GettextSetup.locales_path,
                             pot_file = nil, po_file = nil)
      GettextSetup.initialize(locales_path)
      pot_file ||= GettextSetup::Pot.pot_file_path
      po_file ||= GettextSetup::Pot.po_file_path(language)

      language ||= ENV['LANGUAGE']

      # Let's do some pre-verification of the environment.
      if language.nil?
        puts "You need to specify the language to add. Either 'LANGUAGE=eo rake gettext:po' or 'rake gettext:po[LANGUAGE]'"
        return
      end

      language_path = File.dirname(po_file)
      FileUtils.mkdir_p(language_path)

      if File.exist?(po_file)
        cmd = "msgmerge -U #{po_file} #{pot_file}"
        _, _, _, wait = Open3.popen3(cmd)
        exitstatus = wait.value
        if exitstatus.success?
          puts "PO file #{po_file} merged"
          true
        else
          puts 'PO file merge failed'
          false
        end
      else
        cmd = "msginit --no-translator -l #{language} -o #{po_file} -i #{pot_file}"
        _, _, _, wait = Open3.popen3(cmd)
        exitstatus = wait.value
        if exitstatus.success?
          puts "PO file #{po_file} created"
          true
        else
          puts 'PO file creation failed'
          false
        end
      end
    end

    def self.update_pot(locales_path = GettextSetup.locales_path, path = nil)
      GettextSetup.initialize(locales_path)
      path ||= pot_file_path

      if !File.exist? path
        puts 'No existing POT file, generating new'
        result = GettextSetup::Pot.generate_new_pot(locales_path, path)
        puts "POT file #{path} has been generated" if result
        result
      else
        old_pot = path + '.old'
        File.rename(path, old_pot)
        result = GettextSetup::Pot.generate_new_pot(locales_path, path)
        if !result
          puts 'POT creation failed'
          result
        elsif GettextSetup::Pot.string_changes?(old_pot, path)
          puts 'String changes detected, replacing with updated POT file'
          File.delete(old_pot)
          true
        else
          puts 'No string changes detected, keeping old POT file'
          File.rename(old_pot, path)
          true
        end
      end
    end
  end
end
