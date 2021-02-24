$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_vue"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_vue"
  s.summary     = "ExtVue"
  s.description = "ExtVue"
  s.license     = "GPL-3.0"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md"]
end
