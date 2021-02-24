$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mix_rescue"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mix_rescue"
  s.summary     = "MixRescue"
  s.description = "MixRescue"
  s.license     = "GPL-3.0"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md"]

  s.add_dependency 'actionview'
  s.add_dependency 'mail'
  s.add_dependency 'rack-attack'
  s.add_dependency 'mix_setting'
  s.add_dependency 'mix_global'
  s.add_dependency 'mix_log', version
  # TODO https://www.imaginarycloud.com/blog/rails-send-emails-with-style/
end
