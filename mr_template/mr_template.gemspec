$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = MrBackend::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mr_template"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mr_template"
  s.summary     = "MrTemplate"
  s.description = "MrTemplate"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency 'query_diet', '~> 0.6'
  s.add_dependency 'nestive', '~> 0.6'
end
