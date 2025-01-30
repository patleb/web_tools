$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mix_file"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mix_file"
  s.summary     = "MixFile"
  s.description = "MixFile"
  s.license     = "LGPL-2.1"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md"]

  s.add_dependency 'ext_rails', version
  s.add_dependency 'image_processing'
  s.add_dependency 'image_optim'
  s.add_dependency 'image_optim_pack', '0.10.1.20240317'
end
