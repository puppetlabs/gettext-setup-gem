require "rspec/expectations"
require_relative '../spec_helper'

describe GettextSetup do
  before(:each) do
    GettextSetup.initialize(File::join(File::dirname(File::dirname(__FILE__)), 'fixtures', 'locales'))
  end
  let(:config) do
    GettextSetup.config
  end
  context 'initialize' do
    it "sets up correctly" do
      # GettextSetup.initialize(File::join(File::dirname(File::dirname(__FILE__)), 'fixtures'))
      expect(GettextSetup.locales_path).to match(/\/spec\/fixtures/)
      expect(config['project_name']).to eq('sinatra-i18n')
      expect(config['package_name']).to eq('Sinatra i18n demo')
      expect(config['default_locale']).to eq('en')
      expect(respond_to?(:_)).to eq(true)
    end
  end
  context 'negotiate_locale' do
    it "negotiates correctly" do
      FastGettext.locale = GettextSetup.negotiate_locale('de')
      expect(FastGettext.locale).to eq('de')
      expect(_('Hello, world!')).to eq('Hallo, Welt!')
    end
    it "chooses the default locale when no match is found" do
      expect(GettextSetup.negotiate_locale('no-match')).to eq(config['default_locale'])
    end
    it "chooses the language with the highest q value" do
      expect(GettextSetup.negotiate_locale('en;q=1, de;q=2')).to eq('de')
      expect(GettextSetup.negotiate_locale('en;q=1, de;q=0')).to eq('en')
    end
  end
end
