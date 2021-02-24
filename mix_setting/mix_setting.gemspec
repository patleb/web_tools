$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "mix_setting/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mix_setting"
  s.version     = MixSetting::VERSION
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mix_setting"
  s.summary     = "MixSetting"
  s.description = "MixSetting"
  s.license     = "GPL-3.0"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md"]

  s.add_dependency 'ext_ruby'
  s.add_dependency 'activesupport'
  s.add_dependency 'chronic_duration'
  s.add_dependency 'inifile'
end
