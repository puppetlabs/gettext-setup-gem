require 'rspec/expectations'
require 'rake'
require_relative '../../spec_helper.rb'

load File.expand_path('../../../../lib/tasks/gettext.rake', __FILE__)

describe 'gettext.rake' do
  locales = File.expand_path('../../fixtures/locales', File.dirname(__FILE__))
  tmp_locales = File.expand_path('../../fixtures/tmp_locales', File.dirname(__FILE__))
  fixture_locales = File.expand_path('../../fixtures/fixture_locales', File.dirname(__FILE__))
  tmp_pot_path = File.expand_path('sinatra-i18n.pot', tmp_locales)
  merge_locales = File.expand_path('../../fixtures/merge_locales', File.dirname(__FILE__))

  before :each do
    FileUtils.rm_r(tmp_locales, force: true)
    FileUtils.cp_r(locales, tmp_locales)
  end
  after :each do
    GettextSetup.clear
    Rake::Task.tasks.each(&:reenable)
  end
  around :each do |test|
    # Since we have `exit 1` in these rake tasks, we need to explicitly tell
    # rspec that any unexpected errors aren't expected. Otherwise, if a
    # SystemExit error is thrown, it just doesn't finish running the rest of
    # the tests and considers the suite passing...
    expect { test.run }.not_to raise_error
  end
  context Rake::Task['gettext:pot'] do
    it 'outputs correctly' do
      expect do
        GettextSetup.initialize(tmp_locales)
        subject.invoke
      end.to output(/POT file .+\/spec\/fixtures\/tmp_locales\/sinatra-i18n.pot has been generated/).to_stdout
    end
    it 'exits 1 on error' do
      allow(GettextSetup::Pot).to receive(:generate_new_pot).and_return(false)
      expect do
        GettextSetup.initialize(tmp_locales)
        subject.invoke
      end.to raise_error(SystemExit)
    end
  end
  context Rake::Task['gettext:pot'] do
    it 'outputs correctly, when passing a filename' do
      expect do
        GettextSetup.initialize(tmp_locales)
        subject.invoke(File.expand_path('bill.pot', tmp_locales))
      end.to output(/POT file .+\/spec\/fixtures\/tmp_locales\/bill.pot has been generated/).to_stdout
    end
  end
  context Rake::Task['gettext:metadata_pot'] do
    it 'outputs correctly' do
      expect do
        GettextSetup.initialize(tmp_locales)
        subject.invoke
      end.to output(/POT metadata file .+sinatra-i18n_metadata.pot has been generated/).to_stdout
    end
    it 'exits 1 on error' do
      allow(GettextSetup::MetadataPot).to receive(:generate_metadata_pot).and_return(false)
      expect do
        GettextSetup.initialize(tmp_locales)
        subject.invoke
      end.to raise_error(SystemExit)
    end
  end
  context Rake::Task['gettext:po'] do
    it 'outputs correctly' do
      expect do
        GettextSetup.initialize(tmp_locales)
        subject.invoke('de')
      end.to output(/PO file .+de\/sinatra-i18n.po merged/).to_stdout
    end
    it 'exits 1 on error' do
      allow(GettextSetup::Pot).to receive(:generate_new_po).with('de').and_return(false)
      expect do
        GettextSetup.initialize(tmp_locales)
        subject.invoke('de')
      end.to raise_error(SystemExit)
    end
  end
  context Rake::Task['gettext:update_pot'] do
    it 'does not update the POT when no changes are detected' do
      expect do
        GettextSetup.initialize(tmp_locales)
        subject.invoke
      end.to output(/No string changes detected, keeping old POT file/).to_stdout
    end
    it 'can create a new POT' do
      FileUtils.rm(tmp_pot_path)
      expect do
        GettextSetup.initialize(tmp_locales)
        subject.invoke
      end.to output(/No existing POT file, generating new\nPOT file .+sinatra-i18n.pot has been generated/).to_stdout
    end
    it 'can update the POT' do
      fixture_locales_pot = File.expand_path('fixture_locales.pot', fixture_locales)
      FileUtils.cp(fixture_locales_pot, tmp_pot_path)
      expect do
        GettextSetup.initialize(tmp_locales)
        subject.invoke
      end.to output(/String changes detected, replacing with updated POT file/).to_stdout
    end
    it 'exits 1 upon error' do
      allow(GettextSetup::Pot).to receive(:update_pot).and_return(false)
      expect do
        GettextSetup.initialize(tmp_locales)
        subject.invoke
      end.to raise_error(SystemExit)
    end
  end

  context Rake::Task['gettext:merge'] do
    it 'outputs correctly' do
      expect do
        GettextSetup.initialize(merge_locales)
        subject.invoke
      end.to output(/PO files have been successfully merged/).to_stdout
    end
    it 'exits 1 on error' do
      allow(GettextSetup::Pot).to receive(:merge).and_return(false)
      expect do
        GettextSetup.initialize(merge_locales)
        subject.invoke
      end.to raise_error(SystemExit)
    end
  end
end
