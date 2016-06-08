require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end

require_relative '../lib/gettext-setup'
