$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mix_rpc"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mix_rpc"
  s.summary     = "MixRpc"
  s.description = "MixRpc"
  s.license     = "LGPL-2.1"

  s.files = Dir["{app,db,lib}/**/*", "LICENSE", "README.md"]

  s.add_dependency 'mix_server', version
end
