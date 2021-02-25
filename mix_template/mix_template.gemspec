$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mix_template"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mix_template"
  s.summary     = "MixTemplate"
  s.description = "MixTemplate"
  s.license     = "AGPL-3.0"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md"]

  s.add_dependency 'query_diet', '~> 0.6.2' # TODO https://github.com/makandra/query_diet/commit/445debd96e17365fae4c55d849a462db0163c7f4
  s.add_dependency 'nestive'
  s.add_dependency 'ext_pjax', version
end
