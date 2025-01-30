$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mix_admin"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/web_tools"
  s.summary     = "MixAdmin"
  s.description = "MixAdmin"
  s.license     = "LGPL-2.1"

  s.files = Dir["{app,config,lib}/**/*", "LICENSE", "README.md"]

  s.add_dependency 'mix_user', version
  s.add_dependency 'redcarpet'
end
