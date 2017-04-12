require 'simplecov'
require_relative '../lib/gettext-setup'

GettextSetup.initialize(File.join(File.dirname(__FILE__), 'fixtures', 'locales'))

SimpleCov.start do
  add_filter '/spec/'
end

def cmd_present?(cmd)
  # Try to call out to msgcmp, if it doesn't error, we have the tool
  `#{cmd} --version`
  return true
rescue IOError
  return false
end

def msgcmp_present?
  cmd_present?('msgcmp')
end

def msginit_present?
  cmd_present?('msginit')
end

def msgmerge_present?
  cmd_present?('msgmerge')
end

def with_captured_stdout
  old_stdout = $stdout
  $stdout = StringIO.new('', 'w')
  yield
  $stdout.string
ensure
  $stdout = old_stdout
end
