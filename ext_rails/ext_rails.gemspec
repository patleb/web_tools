$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_rails"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_rails"
  s.summary     = "ExtRails"
  s.description = "ExtRails"
  s.license     = "LGPL-2.1"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md"]

  s.add_dependency "rails", WebTools::RAILS_VERSION::STRING
  # s.add_dependency 'active_record_extended'
  s.add_dependency 'active_type'
  s.add_dependency 'arel_extensions'
  s.add_dependency 'date_validator'
  s.add_dependency 'dotiw'
  s.add_dependency 'geared_pagination'
  s.add_dependency 'http_accept_language'
  s.add_dependency 'i18n-debug'
  s.add_dependency 'money-rails'
  s.add_dependency 'monogamy'
  s.add_dependency 'null-logger'
  s.add_dependency 'pg'
  s.add_dependency 'rails-i18n'
  s.add_dependency 'rblineprof'
  s.add_dependency 'rounding'
  s.add_dependency 'shoulda-matchers'
  s.add_dependency 'stateful_enum'
  s.add_dependency 'mix_setting'
  s.add_dependency 'sunzistrano'
  s.add_dependency 'user_agent_parser'
  s.add_dependency 'webrick'
end
