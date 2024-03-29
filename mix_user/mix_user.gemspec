$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mix_user"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mix_user"
  s.summary     = "MixUser"
  s.description = "MixUser"
  s.license     = "AGPL-3.0"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md"]

  s.add_dependency 'devise', '~> 4.7'
  # s.add_dependency 'devise-encryptable', '~> 0.2'
  s.add_dependency 'devise-i18n'
  # TODO https://github.com/ankane/authtrail
  s.add_dependency 'mix_template', version
end
# TODO https://abevoelker.com/skipping-the-database-with-stateless-tokens-a-hidden-rails-gem-and-a-useful-web-technique/
# TODO or rodauth with sequel-activerecord
