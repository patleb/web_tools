$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mix_server"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mix_server"
  s.summary     = "MixServer"
  s.description = "MixServer"
  s.license     = "LGPL-2.1"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md"]

  s.add_dependency 'ext_rails',  version
  s.add_dependency 'mix_global', version
  s.add_dependency 'pghero'
  s.add_dependency 'pg_query'
end
