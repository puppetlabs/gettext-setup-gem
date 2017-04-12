require 'rspec/expectations'
require_relative '../spec_helper.rb'

require_relative '../../lib/gettext-setup'
describe GettextSetup::Pot do
  NoConfigFoundError = GettextSetup::NoConfigFoundError

  def fixture_locales_path
    File.join(File.dirname(__FILE__), '../fixtures/fixture_locales')
  end

  def spec_locales_path
    File.join(File.dirname(__FILE__), '../fixtures/spec_locales')
  end

  def locales_path
    File.join(File.dirname(__FILE__), '../fixtures/locales')
  end

  describe 'string_changes?', if: msgcmp_present? do
    old_pot = File.absolute_path('../fixtures/string_changes/old.pot', File.dirname(__FILE__))

    it 'should detect string addition' do
      new_pot = File.absolute_path('../fixtures/string_changes/add.pot', File.dirname(__FILE__))
      expect(GettextSetup::Pot.string_changes?(old_pot, new_pot)).to eq(true)
    end

    it 'should detect string removal' do
      new_pot = File.absolute_path('../fixtures/string_changes/remove.pot', File.dirname(__FILE__))
      expect(GettextSetup::Pot.string_changes?(old_pot, new_pot)).to eq(true)
    end

    it 'should detect string changes' do
      new_pot = File.absolute_path('../fixtures/string_changes/change.pot', File.dirname(__FILE__))
      expect(GettextSetup::Pot.string_changes?(old_pot, new_pot)).to eq(true)
    end

    it 'should not detect non-string changes' do
      new_pot = File.absolute_path('../fixtures/string_changes/non_string_changes.pot', File.dirname(__FILE__))
      expect(GettextSetup::Pot.string_changes?(old_pot, new_pot)).to eq(false)
    end
  end

  context 'generate_new_pot' do
    it "fails when GettextSetup can't find a config.yaml" do
      path = File.join(Dir.mktmpdir, 'empty.pot')
      with_captured_stdout do
        expect { GettextSetup::Pot.generate_new_pot(Dir.mktmpdir, path) }.to raise_error(NoConfigFoundError)
      end
    end
    it 'builds a POT file' do
      path = File.join(Dir.mktmpdir, 'new.pot')
      out = with_captured_stdout do
        GettextSetup::Pot.generate_new_pot(fixture_locales_path, path)
      end
      expect(out).to eq('') # STDOUT is determined in `update_pot`.
      contents = File.read(path)
      expect(contents).to match(/Fixture locales/)
      expect(contents).to match(/docs@puppetlabs.com/)
      expect(contents).to match(/Puppet, LLC/)
      expect(contents).to match(/test_strings.rb:1/)
    end
  end

  context 'generate_new_po' do
    it "fails when GettextSetup can't find a config.yaml" do
      path = File.join(Dir.mktmpdir, 'fails.pot')
      po_path = File.join(Dir.mktmpdir, 'fails.po')
      with_captured_stdout do
        expect { GettextSetup::Pot.generate_new_po('ja', Dir.mktmpdir, path, po_path) }.to raise_error(NoConfigFoundError)
      end
    end
    it 'complains when no language is supplied' do
      stdout = with_captured_stdout do
        GettextSetup::Pot.generate_new_po(nil, fixture_locales_path, Dir.mktmpdir, Dir.mktmpdir)
      end
      result = "You need to specify the language to add. Either 'LANGUAGE=eo rake gettext:po' or 'rake gettext:po[LANGUAGE]'\n"
      expect(stdout).to eq(result)
    end
    it 'generates new PO file', if: msginit_present? do
      po_path = File.join(Dir.mktmpdir, 'aa', 'tmp.po')
      pot_path = File.join(locales_path, 'sinatra-i18n.pot')

      stdout = with_captured_stdout do
        GettextSetup::Pot.generate_new_po('aa', locales_path, pot_path, po_path)
      end
      expect(stdout).to eq("PO file #{po_path} created\n")
    end
    it 'merges PO files', if: [msginit_present?, msgmerge_present?] do
      _('merged-po-file')
      po_path = File.join(Dir.mktmpdir, 'aa', 'tmp.po')
      pot_path = GettextSetup::Pot.pot_file_path

      stdout = with_captured_stdout do
        GettextSetup::Pot.generate_new_po('aa', fixture_locales_path, pot_path, po_path)
      end
      expect(stdout).to eq("PO file #{po_path} created\n")
      contents = File.read(po_path)
      expect(contents).to match(/msgid "Hello, world!"/)

      new_pot_path = File.join(spec_locales_path, 'sinatra-i18n.pot')
      new_stdout = with_captured_stdout do
        GettextSetup::Pot.generate_new_po('aa', spec_locales_path, new_pot_path, po_path)
      end
      expect(new_stdout).to eq("PO file #{po_path} merged\n")
      new_contents = File.read(po_path)
      expect(new_contents).to match(/merged-po-file/)
    end
  end

  context 'update_pot' do
    it "fails when GettextSetup can't find a config.yaml" do
      path = File.join(Dir.mktmpdir, 'fail-update.pot')
      with_captured_stdout do
        expect { GettextSetup::Pot.update_pot(Dir.mktmpdir, path) }.to raise_error(NoConfigFoundError)
      end
    end
    it 'creates POT when absent' do
      _('no-pot-file')
      path = File.join(Dir.mktmpdir, 'some-pot.pot')
      stdout = with_captured_stdout do
        GettextSetup::Pot.update_pot(spec_locales_path, path)
      end
      expect(stdout).to eq("No existing POT file, generating new\nPOT file #{path} has been generated\n")
      contents = File.read(path)
      expect(contents).to match(/msgid "no-pot-file"/)
    end
    it 'updates POT when something changes', if: [msginit_present?, msgmerge_present?] do
      _('some-spec-only-string')
      path = File.join(Dir.mktmpdir, 'some-pot.pot')
      stdout = with_captured_stdout do
        GettextSetup::Pot.update_pot(fixture_locales_path, path)
      end
      expect(stdout).to eq("No existing POT file, generating new\nPOT file #{path} has been generated\n")
      contents = File.read(path)
      expect(contents).to match(/Language-Team: LANGUAGE <LL@li.org>/)
      expect(contents).not_to match(/some-spec-only-string/)
      output = with_captured_stdout do
        GettextSetup::Pot.update_pot(spec_locales_path, path)
      end
      new_contents = File.read(path)
      expect(new_contents).to match(/some-spec-only-string/)
      expect(output).to eq("String changes detected, replacing with updated POT file\n")
    end
    it "doesn't update the POT when nothing changes", if: [msginit_present?, msgcmp_present?] do
      _('unchanged-string')
      path = File.join(Dir.mktmpdir, 'some-pot.pot')
      stdout = with_captured_stdout do
        GettextSetup::Pot.update_pot(spec_locales_path, path)
      end
      expect(stdout).to eq("No existing POT file, generating new\nPOT file #{path} has been generated\n")
      contents = File.read(path)
      expect(contents).to match(/unchanged-string/)
      new_stdout = with_captured_stdout do
        GettextSetup::Pot.update_pot(spec_locales_path, path)
      end
      new_contents = File.read(path)
      expect(new_contents).to eq(contents)
      expect(new_stdout).to eq("No string changes detected, keeping old POT file\n")
    end
  end
end
