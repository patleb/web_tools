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
  s.licenses    = ["AGPL-3.0", "MIT"]

  s.files = Dir["{app,config,db,lib,vendor}/**/*", "LICENSE", "README.md"]

  s.add_dependency 'ext_ruby', version
  s.add_dependency 'turbolinks'
  # TODO https://htmx.org/docs/
  # TODO https://westonganger.com/#open-source-software
  # TODO https://github.com/rails/requestjs-rails
end
