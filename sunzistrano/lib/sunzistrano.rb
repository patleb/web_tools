require 'thor'
require 'mix_setting'
require 'sunzistrano/cli'
require 'sunzistrano/cloud'
require 'sunzistrano/version'
require 'sunzistrano/rake/dsl' if defined? Rails

module Sunzistrano
  def self.root
    @root ||= Pathname.new(File.dirname(__dir__)).expand_path
  end
end
