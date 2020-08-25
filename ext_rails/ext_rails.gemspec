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
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency "rails", "~> #{WebTools::RAILS_VERSION::STRING}"
  s.add_dependency 'active_type'
  s.add_dependency 'activerecord-postgis-adapter'
  s.add_dependency 'arel_extensions'
  s.add_dependency 'date_validator'
  s.add_dependency 'discard'
  s.add_dependency 'email_prefixer'
  s.add_dependency 'http_accept_language'
  s.add_dependency 'i18n-debug'
  s.add_dependency 'jsonb_accessor'
  s.add_dependency 'mail_interceptor'
  s.add_dependency 'money-rails'
  s.add_dependency 'monogamy'
  s.add_dependency 'null-logger'
  s.add_dependency 'pg'
  s.add_dependency 'pycall'
  s.add_dependency 'rails-i18n'
  s.add_dependency 'rails_select_on_includes'
  s.add_dependency 'rblineprof'
  s.add_dependency 'rgeo'
  # s.add_dependency 'sequel-activerecord-adapter'
  s.add_dependency 'term-ansicolor'
  s.add_dependency 'mix_setting'
  s.add_dependency 'sunzistrano'
end
