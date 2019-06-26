require 'mr_setting/version'
require 'mr_setting/setting'
require 'mr_setting/railtie' if defined? Rails

module MrSetting
  def self.root
    @root ||= Pathname.new(File.dirname(__dir__)).expand_path
  end
end
