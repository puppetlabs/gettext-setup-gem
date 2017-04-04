require 'open3'

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

  # if file is a directory, take it out of the array. directories
  # cause rxgettext to error out.
  (files - exclusions).reject { |file| File.directory?(file) }
end

def pot_file_path
  File.join(locale_path, GettextSetup.config['project_name'] + '.pot')
end

def generate_new_pot
  config = GettextSetup.config
  package_name = config['package_name']
  project_name = config['project_name']
  bugs_address = config['bugs_address']
  copyright_holder = config['copyright_holder']
  # Done this way to allow the user to enter an empty string in the config.
  comments_tag = config.key?('comments_tag') ? config['comments_tag'] : 'TRANSLATORS'
  version = `git describe`
  system("rxgettext -o locales/#{project_name}.pot --no-wrap --sort-by-file " \
         "--add-comments#{comments_tag.to_s == '' ? '' : '=' + comments_tag} --msgid-bugs-address '#{bugs_address}' " \
         "--package-name '#{package_name}' " \
         "--package-version '#{version}' " \
         "--copyright-holder='#{copyright_holder}' --copyright-year=#{Time.now.year} " +
         files_to_translate.join(' '))
end

def string_changes?(old_pot, new_pot)
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