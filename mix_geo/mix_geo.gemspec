$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mix_geo"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mix_geo"
  s.summary     = "MixGeo"
  s.description = "MixGeo"
  s.license     = "AGPL-3.0"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md"]

  # TODO https://github.com/loureirorg/city-state
  # TODO https://github.com/carmen-ruby/carmen
  s.add_dependency 'ext_ruby', version
  s.add_dependency 'countries', '3.0.1'
  # s.add_dependency 'ip_location_db', '2.2.2020121618'
  s.add_dependency 'rgeo'
  s.add_dependency 'matplotlib'
  s.add_dependency 'activerecord-postgis-adapter'
end
