# -*- encoding: utf-8 -*-

require 'fast_gettext'
require 'yaml'

module GettextSetup
  def self.locales_path
    File.absolute_path('../../locales', File.dirname(__FILE__))
  end

  def self.config
    path = File.absolute_path('config.yaml', locales_path)
    @@config ||= YAML.load_file(path)['gettext']
  end

  def self.default_locale
    config['default_locale'] || "en"
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
    return FastGettext.default_locale if accept_header.nil?
    accept_header.split(",").map do |locale|
      pair = locale.strip.split(';q=')
      pair << '1.0' unless pair.size == 2
      pair[0] = FastGettext.default_locale if pair[0] == '*'
      pair
    end.sort_by do |(locale,qvalue)|
      qvalue.to_f
    end.select do |(locale,_)|
      FastGettext.available_locales.include?(locale)
    end.last.first
  end

  # Make the translation methods available everywhere
  Object.send(:include, FastGettext::Translation)

  # Define our text domain, and set the path into our root.  I would prefer to
  # have something smarter, but we really want this up earlier even than our
  # config loading happens so that errors there can be translated.
  #
  # We use the PO files directly, since it works about as efficiently with
  # fast_gettext, and avoids all the extra overhead of compilation down to
  # machine format, etc.
  FastGettext.add_text_domain(config['project_name'],
                              :path => locales_path,
                              :type => :po,
                              :ignore_fuzzy => true)
  FastGettext.default_text_domain = config['project_name']

  # Likewise, be explicit in our default language choice.
  FastGettext.default_locale = default_locale
  FastGettext.default_available_locales = locales
end
