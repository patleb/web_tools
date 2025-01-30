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
  s.license     = "LGPL-2.1"

  s.files = Dir["lib/**/*", "LICENSE", "README.md"]

  s.add_dependency 'ext_ruby'
end
