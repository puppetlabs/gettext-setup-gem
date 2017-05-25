require 'rspec/expectations'
require 'tmpdir'
require_relative '../../spec_helper'

require_relative '../../../lib/gettext-setup'

describe GettextSetup::MetadataPot do
  before(:each) do
    GettextSetup.initialize(File.absolute_path(File.join(File.dirname(__FILE__), '../../fixtures/locales')))
  end
  context '#metadata_path' do
    it 'finds the right metadata path' do
      expect(GettextSetup::MetadataPot.metadata_path).to match(/sinatra-i18n_metadata\.pot/)
    end
  end
  context '#pot_string' do
    it 'generates a reasonable POT string' do
      expect(GettextSetup::MetadataPot.pot_string({})).to match(/Last-Translator: FULL NAME <EMAIL@ADDRESS>/)
    end
    it 'includes summary when provided' do
      metadata = { 'summary' => 'abc' }
      expect(GettextSetup::MetadataPot.pot_string(metadata)).to match(/msgid "abc"/)
    end
    it 'includes summary when provided' do
      metadata = { 'description' => 'def' }
      expect(GettextSetup::MetadataPot.pot_string(metadata)).to match(/msgid "def"/)
    end
    it 'includes both summary and description when provided' do
      metadata = { 'summary' => 'abc', 'description' => 'def' }
      result = expect(GettextSetup::MetadataPot.pot_string(metadata))
      result.to match(/msgid "def"/)
      result.to match(/msgid "abc"/)
    end
  end
  context '#load_metadata' do
    it 'loads metadata correctly' do
      Dir.mktmpdir do |dir|
        file = File.join(dir, 'metadata.json')
        File.open(file, 'w') { |f| f.write('{"description":"abcdef", "summary":"ghi"}') }
        metadata = GettextSetup::MetadataPot.metadata(File.join(dir, 'metadata.json').to_s)
        expect(metadata).to eq('description' => 'abcdef', 'summary' => 'ghi')
      end
    end
    it 'uses an empty hash if no metadata.json is found' do
      metadata = GettextSetup::MetadataPot.metadata(File.join(Dir.mktmpdir, 'metadata.json').to_s)
      expect(metadata).to eq({})
    end
  end
  context '#generate_metadata_pot' do
    it 'works with everything supplied' do
      dir = Dir.mktmpdir
      file = File.join(dir, 'metadata.pot')
      metadata = { 'description' => 'abc', 'summary' => 'def' }
      GettextSetup::MetadataPot.generate_metadata_pot(metadata,
                                                      file)
      contents = File.read(file)
      expect(contents).to match(/msgid "abc"/)
      expect(contents).to match(/msgid "def"/)
    end
  end
end
