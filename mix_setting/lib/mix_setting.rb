require 'mix_setting/version'
require 'mix_setting/setting'
require 'mix_setting/railtie' if defined? Rails.env

module MixSetting
  def self.root
    @root ||= Pathname.new(File.dirname(__dir__)).expand_path
  end
end
