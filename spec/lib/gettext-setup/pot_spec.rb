require 'rspec/expectations'
require 'tmpdir'
require_relative '../../spec_helper.rb'

require_relative '../../../lib/gettext-setup'
describe GettextSetup::Pot do
  NoConfigFoundError = GettextSetup::NoConfigFoundError

  def fixture_locales_path
    File.join(File.dirname(__FILE__), '../../fixtures/fixture_locales')
  end

  def spec_locales_path
    File.join(File.dirname(__FILE__), '../../fixtures/spec_locales')
  end

  def locales_path
    File.join(File.dirname(__FILE__), '../../fixtures/locales')
  end

  def merge_locales_path
    File.join(File.dirname(__FILE__), '../../fixtures/merge_locales')
  end

  describe 'string_changes?', if: msgcmp_present? do
    old_pot = File.absolute_path('../../fixtures/string_changes/old.pot', File.dirname(__FILE__))

    it 'should detect string addition' do
      new_pot = File.absolute_path('../../fixtures/string_changes/add.pot', File.dirname(__FILE__))
      expect(GettextSetup::Pot.string_changes?(old_pot, new_pot)).to eq(true)
    end

    it 'should detect string removal' do
      new_pot = File.absolute_path('../../fixtures/string_changes/remove.pot', File.dirname(__FILE__))
      expect(GettextSetup::Pot.string_changes?(old_pot, new_pot)).to eq(true)
    end

    it 'should detect string changes' do
      new_pot = File.absolute_path('../../fixtures/string_changes/change.pot', File.dirname(__FILE__))
      expect(GettextSetup::Pot.string_changes?(old_pot, new_pot)).to eq(true)
    end

    it 'should not detect non-string changes' do
      new_pot = File.absolute_path('../../fixtures/string_changes/non_string_changes.pot', File.dirname(__FILE__))
      expect(GettextSetup::Pot.string_changes?(old_pot, new_pot)).to eq(false)
    end
  end

  context 'generate_new_pot' do
    it "fails when GettextSetup can't find a config.yaml" do
      path = File.join(Dir.mktmpdir, 'empty.pot')
      expect { GettextSetup::Pot.generate_new_pot(locales_path: Dir.mktmpdir, target_path: path) }.to raise_error(NoConfigFoundError)
    end
    it 'builds a POT file' do
      path = File.join(Dir.mktmpdir, 'new.pot')
      expect do
        GettextSetup::Pot.generate_new_pot(locales_path: fixture_locales_path, target_path: path)
      end.to output('').to_stdout # STDOUT is determined in `update_pot`.
      contents = File.read(path)
      expect(contents).to match(/Fixture locales/)
      expect(contents).to match(/docs@puppetlabs.com/)
      expect(contents).to match(/Puppet, LLC/)
      expect(contents).to match(/test_strings.rb:1/)
    end
    it 'builds a POT file with :header_only' do
      path = File.join(Dir.mktmpdir, 'new.pot')
      expect do
        GettextSetup::Pot.generate_new_pot(locales_path: fixture_locales_path, target_path: path, header_only: true)
      end.to output('').to_stdout # STDOUT is determined in `update_pot`
      contents = File.read(path)
      expect(contents).to_not match(/Hello, world/)
      expect(contents).to match(/Fixture locales/)
      expect(contents).to match(/docs@puppetlabs.com/)
      expect(contents).to match(/Puppet, LLC/)
    end
  end

  context 'generate_new_po' do
    it "fails when GettextSetup can't find a config.yaml" do
      path = File.join(Dir.mktmpdir, 'fails.pot')
      po_path = File.join(Dir.mktmpdir, 'fails.po')
      expect { GettextSetup::Pot.generate_new_po('ja', Dir.mktmpdir, path, po_path) }.to raise_error(NoConfigFoundError)
    end
    it 'complains when no language is supplied' do
      result = "You need to specify the language to add. Either 'LANGUAGE=eo rake gettext:po' or 'rake gettext:po[LANGUAGE]'\n"
      expect do
        GettextSetup::Pot.generate_new_po(nil, fixture_locales_path, Dir.mktmpdir, Dir.mktmpdir)
      end.to output(result).to_stdout
    end
    it 'generates new PO file', if: msginit_present? do
      po_path = File.join(Dir.mktmpdir, 'aa', 'tmp.po')
      pot_path = File.join(locales_path, 'sinatra-i18n.pot')

      expect do
        GettextSetup::Pot.generate_new_po('aa', locales_path, pot_path, po_path)
      end.to output("PO file #{po_path} created\n").to_stdout
    end
    it 'merges PO files', if: [msginit_present?, msgmerge_present?] do
      _('merged-po-file')
      po_path = File.join(Dir.mktmpdir, 'aa', 'tmp.po')
      pot_path = GettextSetup::Pot.pot_file_path

      expect do
        GettextSetup::Pot.generate_new_po('aa', fixture_locales_path, pot_path, po_path)
      end.to output("PO file #{po_path} created\n").to_stdout
      contents = File.read(po_path)
      expect(contents).to match(/msgid "Hello, world!"/)

      new_pot_path = File.join(spec_locales_path, 'sinatra-i18n.pot')
      expect do
        GettextSetup::Pot.generate_new_po('aa', spec_locales_path, new_pot_path, po_path)
      end.to output("PO file #{po_path} merged\n").to_stdout
      new_contents = File.read(po_path)
      expect(new_contents).to match(/merged-po-file/)
    end
  end

  context 'update_pot' do
    it "fails when GettextSetup can't find a config.yaml" do
      path = File.join(Dir.mktmpdir, 'fail-update.pot')
      expect { GettextSetup::Pot.update_pot(Dir.mktmpdir, path) }.to raise_error(NoConfigFoundError)
    end
    it 'creates POT when absent' do
      _('no-pot-file')
      path = File.join(Dir.mktmpdir, 'some-pot.pot')
      expect do
        GettextSetup::Pot.update_pot(spec_locales_path, path)
      end.to output("No existing POT file, generating new\nPOT file #{path} has been generated\n").to_stdout
      contents = File.read(path)
      expect(contents).to match(/msgid "no-pot-file"/)
    end
    it 'updates POT when something changes', if: [msginit_present?, msgmerge_present?] do
      _('some-spec-only-string')
      path = File.join(Dir.mktmpdir, 'some-pot.pot')
      expect do
        GettextSetup::Pot.update_pot(fixture_locales_path, path)
      end.to output("No existing POT file, generating new\nPOT file #{path} has been generated\n").to_stdout
      contents = File.read(path)
      expect(contents).to match(/Language-Team: LANGUAGE <LL@li.org>/)
      expect(contents).not_to match(/some-spec-only-string/)
      expect do
        GettextSetup::Pot.update_pot(spec_locales_path, path)
      end.to output("String changes detected, replacing with updated POT file\n").to_stdout
      new_contents = File.read(path)
      expect(new_contents).to match(/some-spec-only-string/)
    end
    it "doesn't update the POT when nothing changes", if: [msginit_present?, msgcmp_present?] do
      _('unchanged-string')
      path = File.join(Dir.mktmpdir, 'some-pot.pot')
      expect do
        GettextSetup::Pot.update_pot(spec_locales_path, path)
      end.to output("No existing POT file, generating new\nPOT file #{path} has been generated\n").to_stdout
      contents = File.read(path)
      expect(contents).to match(/unchanged-string/)
      expect do
        GettextSetup::Pot.update_pot(spec_locales_path, path)
      end.to output("No string changes detected, keeping old POT file\n").to_stdout
      new_contents = File.read(path)
      expect(new_contents).to eq(contents)
    end
  end
  context 'Merge pot files' do
    # setup
    before :all do
      { 'ruby' => 'ruby.pot', 'puppet' => 'puppet.pot', 'metadata' => 'metadata.pot' }.each do |pot_type, pot_name|
        File.open(File.join(merge_locales_path, pot_name), 'w') do |file|
          file.write <<-POT
  # Copyright (C) 2017 Puppet, Inc.
  # This file is distributed under the same license as the puppetlabs-mysql package.
  # FIRST AUTHOR <EMAIL@ADDRESS>, 2017.
  #
  #, fuzzy
  msgid ""
  msgstr ""
  "Project-Id-Version: puppetlabs-mysql 3.11.0-30-g4cc0bbf\\n"
  "Report-Msgid-Bugs-To: docs@puppet.com\\n"
  "POT-Creation-Date: 2017-08-26 21:30+0100\\n"
  "PO-Revision-Date: 2017-08-26 21:30+0100\\n"
  "Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
  "Language-Team: LANGUAGE <LL@li.org>\\n"
  "MIME-Version: 1.0\\n"
  "Content-Type: text/plain; charset=UTF-8\\n"
  "Content-Transfer-Encoding: 8bit\\n"
  "Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\\n"

  #: ../lib/puppet/parser/functions/mysql_strip_hash.rb:11
  msgid "this is a #{pot_type} string"
  msgstr ""
        POT
        end
      end
    end
    it 'merges pot files' do
      expect do
        GettextSetup::Pot.merge(locales_path: merge_locales_path)
      end.to output(%r{PO files have been successfully merged}).to_stdout
      contents = File.read(File.join(merge_locales_path, GettextSetup.config['project_name'] + '.pot'))
      expect(contents).to match(%r{.*\"this is a metadata string\".*})
      expect(contents).to match(%r{.*\"this is a puppet string\".*})
      expect(contents).to match(%r{.*\"this is a ruby string\".*})
    end

    it 'creates an oldpot file if one already exists' do
      expect do
        GettextSetup::Pot.merge(locales_path: merge_locales_path)
      end.to output("Warning - merge_locales.pot already exists and will be relocated to oldpot/old_merge_locales.pot.\nPO files have been successfully merged, merge_locales.pot has been created.\n").to_stdout
      file = File.expand_path('oldpot/old_merge_locales.pot', merge_locales_path)
      expect(File.exist?(file)).to be true
    end

    # cleanup
    after :all do
      FileUtils.rm(Dir.glob("#{merge_locales_path}/*.pot"))
      FileUtils.rm_rf("#{merge_locales_path}/oldpot")
    end
  end
end
