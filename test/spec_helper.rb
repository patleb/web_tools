ENV['RAILS_ENV'] ||= 'test'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
ENV['BOOTSNAP_CACHE_DIR'] ||= File.expand_path('../tmp/cache', __dir__)
require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'ext_minitest/spec_help'
require 'minitest/ext_rice'
