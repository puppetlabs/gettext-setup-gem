require 'fast_gettext'
require 'yaml'
require 'locale'

module GettextSetup
  class NoConfigFoundError < RuntimeError
    def initialize(path)
      super("No config.yaml found! (searching: #{path})")
    end
  end

  @config = nil
  @translation_repositories = {}

  # `locales_path` should include:
  # - config.yaml
  # - a .pot file for the project
  # - i18n directories for languages, each with a .po file
  # - if using .mo files, an LC_MESSAGES dir in each language dir, with the .mo file in it
  # valid `options` fields:
  # :file_format - one of the supported backends for fast_gettext (e.g. :po, :mo, :yaml, etc.)
  def self.initialize(locales_path = 'locales', options = {})
    GettextSetup.initialize_config(locales_path)

    # Make the translation methods available everywhere
    Object.send(:include, FastGettext::Translation)

    # Define our text domain, and set the path into our root.  I would prefer to
    # have something smarter, but we really want this up earlier even than our
    # config loading happens so that errors there can be translated.
    add_repository_to_chain(config['project_name'], options)

    # 'chain' is the only available multi-domain type in fast_gettext 1.1.0 We should consider
    # investigating 'merge' once we can bump our dependency
    FastGettext.add_text_domain('master_domain', type: :chain, chain: @translation_repositories.values)
    FastGettext.default_text_domain = 'master_domain'

    # Likewise, be explicit in our default language choice. Available locales
    # must be set prior to setting the default_locale since default locale must
    # available.
    FastGettext.default_available_locales = (FastGettext.default_available_locales || []) | locales
    FastGettext.default_locale = default_locale

    Locale.set_default(default_locale)
  end

  # Sets up the config class variables.
  #
  # Call this without calling initialize when you only need to deal with the
  # translation files and you don't need runtime translation.
  def self.initialize_config(locales_path = 'locales')
    config_path = File.absolute_path('config.yaml', locales_path)
    File.exist?(config_path) || raise(NoConfigFoundError, config_path)

    @config = YAML.load_file(config_path)['gettext']
    @locales_path = locales_path
  end

  def self.config?
    raise NoConfigFoundError, File.join(locales_path, 'config.yaml') unless @config
    @config
  end

  def self.add_repository_to_chain(project_name, options)
    repository = FastGettext::TranslationRepository.build(project_name,
                                                          path: locales_path,
                                                          type: options[:file_format] || :po,
                                                          ignore_fuzzy: false)
    @translation_repositories[project_name] = repository unless @translation_repositories.key? project_name
  end

  def self.locales_path
    @locales_path ||= File.join(Dir.pwd, 'locales')
  end

  def self.config
    @config ||= {}
  end

  def self.translation_repositories
    @translation_repositories
  end

  def self.default_locale
    config['default_locale'] || 'en'
  end

  def self.default_locale=(new_locale)
    FastGettext.default_locale = new_locale
    Locale.set_default(new_locale)
    config['default_locale'] = new_locale
  end

  # Returns the locale for the current machine. This is most useful for shell
  # applications that need an ACCEPT-LANGUAGE header set.
  def self.candidate_locales
    Locale.candidates(type: :cldr).join(',')
  end

  def self.clear
    Locale.clear
  end

  def self.locales
    explicit = Dir.glob(File.absolute_path('*/*.po', locales_path)).map do |x|
      File.basename(File.dirname(x))
    end
    ([default_locale] + explicit).uniq
  end

  # Given an HTTP Accept-Language header return the locale with the highest
  # priority from it for which we have a locale available. If none exists,
  # return the default locale
  def self.negotiate_locale(accept_header)
    unless @config
      raise ArgumentError, 'No config.yaml found! Use `GettextSetup.initialize(locales_path)` to locate your config.yaml'
    end
    return FastGettext.default_locale if accept_header.nil?
    available_locales = accept_header.split(',').map do |locale|
      pair = locale.strip.split(';q=')
      pair << '1.0' unless pair.size == 2
      # Ignore everything but the language itself; that means that we treat
      # 'de' and 'de-DE' identical, and would use the 'de' message catalog
      # for both.
      pair[0] = pair[0].split('-')[0]
      pair[0] = FastGettext.default_locale if pair[0] == '*'
      pair
    end.sort_by do |(_, qvalue)|
      -1 * qvalue.to_f
    end.select do |(locale, _)|
      FastGettext.available_locales.include?(locale)
    end
    if available_locales && available_locales.first
      available_locales.first.first
    else
      # We can't satisfy the request preference. Just use the default locale.
      default_locale
    end
  end

  # Negotiates and sets the locale based on an accept language header.
  def self.negotiate_locale!(accept_header)
    FastGettext.locale = negotiate_locale(accept_header)
  end
end
