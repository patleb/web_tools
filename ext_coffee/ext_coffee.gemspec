$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_coffee"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_coffee"
  s.summary     = "ExtCoffee"
  s.description = "ExtCoffee"
  s.licenses    = ["LGPL-2.1", "MIT"]

  s.files = Dir["{app,config,lib,vendor}/**/*", "LICENSE", "README.md"]

  s.add_dependency 'ext_ruby', version
end
