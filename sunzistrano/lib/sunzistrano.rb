require 'open3'
require 'ostruct'
require 'net/ssh'
require 'thor'
require 'rainbow'
# Starting 2.0.0, Rainbow no longer patches string with the color method by default.
require 'rainbow/version'
require 'rainbow/ext/string' unless Rainbow::VERSION < '2.0.0'
require 'bcrypt'
require 'active_support/string_inquirer'
require 'active_support/core_ext/array/wrap'
require 'mr_secret' if Gem.loaded_specs['mr_secret']
require 'sun_cap/sunzistrano' if Gem.loaded_specs['sun_cap']
require 'sunzistrano/config'
require 'sunzistrano/cli'
require 'sunzistrano/version'

module Sunzistrano
  def self.root
    @root ||= Pathname.new(File.dirname(__dir__)).expand_path
  end
end
