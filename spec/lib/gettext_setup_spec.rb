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
      GettextSetup.locales_path.should =~ /\/spec\/fixtures/
      config['project_name'].should == 'sinatra-i18n'
      config['package_name'].should == 'Sinatra i18n demo'
      config['default_locale'].should == 'en'
      respond_to?(:_).should == true
    end
  end
  context 'negotiate_locale' do
    it "negotiates correctly" do
      FastGettext.locale = GettextSetup.negotiate_locale('de')
      FastGettext.locale.should == 'de'
      _('Hello, world!').should == 'Hallo, Welt!'
    end
    it "chooses the default locale when no match is found" do
      GettextSetup.negotiate_locale('no-match').should == config['default_locale']
    end
    it "chooses the language with the highest q value" do
      GettextSetup.negotiate_locale('en;q=1, de;q=2').should == 'de'
      GettextSetup.negotiate_locale('en;q=1, de;q=0').should == 'en'
    end
  end
end
