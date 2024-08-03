$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_shakapacker"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_shakapacker"
  s.summary     = "ExtShakapacker"
  s.description = "ExtShakapacker"
  s.license     = "AGPL-3.0"

  s.files = Dir["lib/**/*", "LICENSE", "README.md"]

  s.add_dependency 'ext_ruby', version
  s.add_dependency 'shakapacker'
end
