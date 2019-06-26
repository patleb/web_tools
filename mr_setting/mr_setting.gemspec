$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "mr_setting/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mr_setting"
  s.version     = MrSetting::VERSION
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mr_setting"
  s.summary     = "MrSetting"
  s.description = "MrSetting"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency 'ext_ruby'
  s.add_dependency 'activesupport'
  s.add_dependency 'chronic_duration'
  s.add_dependency 'inifile'
end
