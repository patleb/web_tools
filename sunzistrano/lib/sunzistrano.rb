require 'thor'
require 'ext_ruby'
require 'mix_setting' if Gem.loaded_specs['mix_setting']
require 'sun_cap/sunzistrano' if Gem.loaded_specs['sun_cap']
require 'sunzistrano/context'
require 'sunzistrano/cli'
require 'sunzistrano/version'

module Sunzistrano
  def self.root
    @root ||= Pathname.new(File.dirname(__dir__)).expand_path
  end
end
