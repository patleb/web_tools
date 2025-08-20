$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_rice"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_rice"
  s.summary     = "ExtRice"
  s.description = "ExtRice"
  s.license     = "LGPL-2.1"

  s.files = Dir["{config,lib,vendor}/**/*", "LICENSE", "README.md"]

  s.add_dependency 'mix_setting'
  s.add_dependency 'rice', '~> 4.5.0'
end
