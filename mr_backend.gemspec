# Maintain your gem's version:
require_relative "./version"
version = MrBackend::VERSION::STRING # TODO rename to mr_backend_ce with MrBackend

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mr_backend"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mr_backend"
  s.summary     = "MrBackend"
  s.description = "MrBackend"
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency "rails", "~> #{MrBackend::RAILS_VERSION::STRING}"
  s.add_dependency 'sprockets', '~> 3.7'
  s.add_dependency 'active_type', '~> 0.7'
  s.add_dependency 'baby_squeel', '~> 1.2'
  s.add_dependency 'date_validator'
  s.add_dependency 'http_accept_language', '~> 2.1'
  s.add_dependency 'i18n-debug', '~> 1.1'
  s.add_dependency 'money-rails', '~> 1.9'
  s.add_dependency 'monogamy', '>= 0.0.2'
  s.add_dependency 'null-logger', '~> 0.1'
  s.add_dependency 'pg'
  s.add_dependency 'rails-i18n', '~> 5.0'
  s.add_dependency 'rails_select_on_includes'
  s.add_dependency 'rblineprof'
  s.add_dependency 'store_base_sti_class'
  s.add_dependency 'term-ansicolor'
  s.add_dependency 'web-console'
  s.add_dependency 'vmstat'
  s.add_dependency "ext_capistrano", version
  s.add_dependency "ext_minitest",   version
  s.add_dependency "ext_rake",       version
  s.add_dependency "ext_ruby",       version
  s.add_dependency "ext_sql",        version
  s.add_dependency "ext_whenever",   version
  s.add_dependency "mr_backup",      version
  s.add_dependency "mr_core",        version
  s.add_dependency "mr_global",      version
  s.add_dependency "mr_notifier",    version
  s.add_dependency "mr_setting"
  s.add_dependency "mr_rescue",      version
  s.add_dependency "mr_template",    version
  s.add_dependency "mr_throttler",   version
  s.add_dependency "sun_cap",        version
  s.add_dependency "sunzistrano"
end
