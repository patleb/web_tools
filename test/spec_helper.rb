ENV['RAILS_ENV'] ||= 'test'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
ENV['BOOTSNAP_CACHE_DIR'] ||= File.expand_path('../tmp/cache', __dir__)
require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'ext_minitest/spec_help'
require 'minitest/ext_rice'

DUMMY_GEMS = Set.new(%w(
  1st_gem
  2nd_gem
  3rd_gem
))

module Gem
  def self.root(name)
    if DUMMY_GEMS.include? name
      $test.root.join('gems', name)
    elsif (spec = Gem.loaded_specs[name])
      Pathname.new(spec.gem_dir)
    end
  end
end
