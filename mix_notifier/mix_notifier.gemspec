$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mix_notifier"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mix_notifier"
  s.summary     = "MixNotifier"
  s.description = "MixNotifier"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency 'actionview'
  s.add_dependency 'mail'
  s.add_dependency 'mix_setting'
  # TODO https://www.imaginarycloud.com/blog/rails-send-emails-with-style/
end
