require 'mr_secret/version'
require 'mr_secret/secret'
require 'mr_secret/railtie' if defined? Rails

module MrSecret
  def self.root
    @root ||= Pathname.new(File.dirname(__dir__)).expand_path
  end
end
