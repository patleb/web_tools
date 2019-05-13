$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "mr_secret/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mr_secret"
  s.version     = MrSecret::VERSION
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mr_secret"
  s.summary     = "MrSecret"
  s.description = "MrSecret"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency 'ext_ruby'
  s.add_dependency 'activesupport'
  s.add_dependency 'chronic_duration'
  s.add_dependency 'inifile'
end
