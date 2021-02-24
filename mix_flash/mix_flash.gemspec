$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mix_flash"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mix_flash"
  s.summary     = "MixFlash"
  s.description = "MixFlash"
  s.license     = "GPL-3.0"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md"]

  s.add_dependency 'ext_ruby', version
end
