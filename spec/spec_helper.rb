require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

def msgcmp_present?
  # Try to call out to msgcmp, if it doesn't error, we have the tool
  `msgcmp`
  return true
rescue IOError
  return false
end
