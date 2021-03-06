$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_ruby"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_ruby"
  s.summary     = "ExtRuby"
  s.description = "ExtRuby"
  s.license     = "AGPL-3.0"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md"]

  s.add_dependency 'activesupport'
  s.add_dependency 'bcrypt'
  s.add_dependency 'bootsnap'
  s.add_dependency 'colorize'
  s.add_dependency 'ice_nine'
  s.add_dependency 'http'
  s.add_dependency 'oj'
  s.add_dependency 'parallel'
  s.add_dependency 'require_all', '~> 1.5'
  s.add_dependency 'reversed'
  s.add_dependency 'sorted_set'
  s.add_dependency 'vmstat'
end
