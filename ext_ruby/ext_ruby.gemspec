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
  s.license     = "LGPL-2.1"

  s.files = Dir["lib/**/*", "LICENSE", "README.md"]

  s.add_dependency 'activesupport'
  s.add_dependency 'bcrypt'
  s.add_dependency 'bootsnap'
  s.add_dependency 'chronic_duration'
  s.add_dependency 'colorize'
  s.add_dependency 'csv'
  s.add_dependency 'fiddle'
  s.add_dependency 'ice_nine'
  s.add_dependency 'inifile'
  s.add_dependency 'http'
  s.add_dependency 'mutex_m'
  s.add_dependency 'ostruct'
  s.add_dependency 'parallel'
  s.add_dependency 'sorted_set'
  s.add_dependency 'vmstat'
end
