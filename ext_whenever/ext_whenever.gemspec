$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_whenever"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_whenever"
  s.summary     = "ExtWhenever"
  s.description = "ExtWhenever"
  s.license     = "LGPL-2.1"

  s.files = Dir["{config,lib}/**/*", "LICENSE", "README.md"]

  s.add_dependency "whenever"
  s.add_dependency "sunzistrano"
end
