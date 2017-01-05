# -*- encoding: utf-8 -*-
require 'fast_gettext'
require 'yaml'
require 'locale'

module GettextSetup
  @@config = nil

  # `locales_path` should include:
  # - config.yaml
  # - a .pot file for the project
  # - i18n directories for languages, each with a .po file
  # - if using .mo files, an LC_MESSAGES dir in each language dir, with the .mo file in it
  # valid `options` fields:
  # :file_format - one of the supported backends for fast_gettext (e.g. :po, :mo, :yaml, etc.)
  def self.initialize(locales_path, options = {})
    config_path = File.absolute_path('config.yaml', locales_path)
    @@config = YAML.load_file(config_path)['gettext']
    @@locales_path = locales_path

    # Make the translation methods available everywhere
    Object.send(:include, FastGettext::Translation)

    # Define our text domain, and set the path into our root.  I would prefer to
    # have something smarter, but we really want this up earlier even than our
    # config loading happens so that errors there can be translated.
    FastGettext.add_text_domain(config['project_name'],
                                :path => locales_path,
                                :type => options[:file_format] || :po,
                                :ignore_fuzzy => false)
    FastGettext.default_text_domain = config['project_name']

    # Likewise, be explicit in our default language choice.
    FastGettext.default_locale = default_locale
    FastGettext.default_available_locales = locales

    Locale.set_default(default_locale)
  end

  def self.locales_path
    @@locales_path
  end

  def self.config
    @@config
  end

  def self.default_locale
    config['default_locale'] || "en"
  end

  # Returns the locale for the current machine. This is most useful for shell
  # applications that need an ACCEPT-LANGUAGE header set.
  def self.candidate_locales
    Locale.candidates(type: :cldr).join(',')
  end

  def self.locales
    explicit = Dir.glob(File::absolute_path('*/*.po', locales_path)).map do |x|
      File::basename(File::dirname(x))
    end
    (explicit + [ default_locale]).uniq
  end

  # Given an HTTP Accept-Language header return the locale with the highest
  # priority from it for which we have a locale available. If none exists,
  # return the default locale
  def self.negotiate_locale(accept_header)
    unless @@config
      raise ArgumentError, "No config.yaml found! Use `GettextSetup.initialize(locales_path)` to locate your config.yaml"
    end
    return FastGettext.default_locale if accept_header.nil?
    available_locales = accept_header.split(",").map do |locale|
      pair = locale.strip.split(';q=')
      pair << '1.0' unless pair.size == 2
      pair[0] = FastGettext.default_locale if pair[0] == '*'
      pair
    end.sort_by do |(locale,qvalue)|
      qvalue.to_f
    end.select do |(locale,_)|
      FastGettext.available_locales.include?(locale)
    end
    if available_locales and available_locales.last
      available_locales.last.first
    else
      # We can't satisfy the request preference. Just use the default locale.
      default_locale
    end
  end
end
