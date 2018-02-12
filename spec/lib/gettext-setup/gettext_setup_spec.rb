require 'rspec/expectations'
require_relative '../../spec_helper'

require_relative '../../../lib/gettext-setup'

describe GettextSetup do
  locales_path = File.absolute_path(File.join(File.dirname(__FILE__), '../../fixtures/locales'))
  fixture_locales_path = File.absolute_path(File.join(File.dirname(__FILE__), '../../fixtures/fixture_locales'))

  before(:each) do
    GettextSetup.initialize(locales_path)
  end
  after(:each) do
    FastGettext.default_text_domain = nil
    FastGettext.default_available_locales = nil
    FastGettext.default_locale = nil

    FastGettext.text_domain = nil
    FastGettext.available_locales = nil
    FastGettext.locale = nil
  end
  let(:config) do
    GettextSetup.config
  end
  context 'initialize' do
    it 'sets up correctly' do
      expect(GettextSetup.locales_path).to match(/\/spec\/fixtures/)
      expect(config['project_name']).to eq('sinatra-i18n')
      expect(config['package_name']).to eq('Sinatra i18n demo')
      expect(config['default_locale']).to eq('en')
      expect(respond_to?(:_)).to eq(true)
    end
  end
  context 'negotiate_locale' do
    it 'negotiates correctly' do
      FastGettext.locale = GettextSetup.negotiate_locale('de')
      expect(FastGettext.locale).to eq('de')
      expect(_('Hello, world!')).to eq('Hallo, Welt!')
    end
    it 'chooses the default locale when no match is found' do
      expect(GettextSetup.negotiate_locale('no-match')).to eq(config['default_locale'])
    end
    it 'chooses the language with the highest q value' do
      expect(GettextSetup.negotiate_locale('en;q=1, de;q=2')).to eq('de')
      expect(GettextSetup.negotiate_locale('en;q=1, de;q=0')).to eq('en')
    end
    it 'ignores country variant' do
      expect(GettextSetup.negotiate_locale('en;q=1, de-DE;q=2')).to eq('de')
      expect(GettextSetup.negotiate_locale('en;q=1, de-DE;q=0')).to eq('en')
    end
    it 'chooses the first value when q values are equal' do
      expect(GettextSetup.negotiate_locale('de;q=1, en;q=1')).to eq('de')
    end
  end
  context 'negotiate_locale!' do
    it 'sets the locale' do
      GettextSetup.negotiate_locale!('de')
      expect(FastGettext.locale).to eq('de')
      expect(_('Hello, world!')).to eq('Hallo, Welt!')
      GettextSetup.negotiate_locale!('en')
      expect(FastGettext.locale).to eq('en')
      expect(_('Hello, world!')).to eq('Hello, world!')
    end
  end
  context 'setting default_locale' do
    before :each do
      GettextSetup.default_locale = 'en'
    end
    it 'allows setting the default locale' do
      expect(GettextSetup.default_locale).to eq('en')
      GettextSetup.default_locale = 'de'
      expect(GettextSetup.default_locale).to eq('de')
    end
  end
  context 'clear' do
    it 'can clear the locale' do
      expect(GettextSetup.default_locale).to eq('en')
      expect(GettextSetup.candidate_locales).to include('en')
      GettextSetup.clear
      begin
        old_locale = Locale.current
        Locale.current = 'de_DE'
        expect(GettextSetup.candidate_locales).to eq('de_DE,de,en')
      ensure
        Locale.current = old_locale
      end
    end
  end
  context 'multiple locales' do
    # locales/ loads the de locale and fixture_locales/ loads the jp locale
    before(:each) do
      GettextSetup.initialize(fixture_locales_path)
    end
    it 'can aggregate locales across projects' do
      expect(FastGettext.default_available_locales).to include('en')
      expect(FastGettext.default_available_locales).to include('de')
      expect(FastGettext.default_available_locales).to include('jp')
    end
    it 'can switch to loaded locale' do
      FastGettext.locale = GettextSetup.negotiate_locale('de,en')
      expect(FastGettext.locale).to eq('de')
      FastGettext.locale = GettextSetup.negotiate_locale('jp')
      expect(FastGettext.locale).to eq('jp')
    end
  end
  context 'translation repository chain' do
    before(:each) do
      GettextSetup.initialize(fixture_locales_path)
    end
    it 'chain is not nil' do
      expect(GettextSetup.translation_repositories).not_to be_nil
    end
    it 'can translate without switching text domains' do
      FastGettext.locale = 'de'
      expect(_('Hello, world!')).to eq('Hallo, Welt!')
      FastGettext.locale = 'jp'
      expect(_('Hello, world!')).to eq('こんにちは世界')
    end
    it 'does not allow duplicate repositories' do
      GettextSetup.initialize(fixture_locales_path)
      repos = GettextSetup.translation_repositories
      expect(repos.select { |k, _| k == 'fixture_locales' }.size).to eq(1)
    end
    it 'does allow multiple unique domains' do
      GettextSetup.initialize(locales_path)
      repos = GettextSetup.translation_repositories
      expect(repos.size == 2)
      expect(repos.select { |k, _| k == 'fixture_locales' }.size).to eq(1)
      expect(repos.select { |k, _| k == 'sinatra-i18n' }.size).to eq(1)
    end
  end
end
