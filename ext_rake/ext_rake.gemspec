$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_rake"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_rake"
  s.summary     = "ExtRake"
  s.description = "ExtRake"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency "rake"
  # TODO https://github.com/tessi/malloc_trim
  s.add_dependency "dotiw"
  s.add_dependency "ext_ruby", version
  s.add_dependency "mix_setting"
  s.add_dependency "mix_rescue", version
  # TODO https://github.com/stevehodges/attribute_stats
  # TODO https://github.com/thoughtbot/terrapin

  s.add_development_dependency "railties"
  s.add_development_dependency 'ext_minitest', version
end
