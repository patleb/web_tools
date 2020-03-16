require 'thor'
require 'mix_setting'
require 'sunzistrano/cli'
require 'sunzistrano/cloud'
require 'sunzistrano/context'
require 'sunzistrano/version'

module Sunzistrano
  def self.root
    @root ||= Pathname.new(File.dirname(__dir__)).expand_path
  end
end
