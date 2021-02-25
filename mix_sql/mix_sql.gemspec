$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mix_sql"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mix_sql"
  s.summary     = "MixSql"
  s.description = "MixSql"
  s.license     = "AGPL-3.0"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md"]

  s.add_dependency 'activesupport'
  s.add_dependency 'activerecord'
  s.add_dependency 'sql_query'
  s.add_dependency 'mix_task', version
  s.add_dependency 'sunzistrano'

  s.add_development_dependency 'ext_minitest', version
  # TODO https://github.com/crashtech/torque-postgresql
end
