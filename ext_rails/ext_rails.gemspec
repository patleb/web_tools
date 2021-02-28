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
  s.license     = "AGPL-3.0"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md"]

  s.add_dependency "rails", "~> #{WebTools::RAILS_VERSION::STRING}"
  s.add_dependency 'active_type'
  s.add_dependency 'arel_extensions'
  # TODO Rails 6.1 check constraint for non-empty arrays or https://github.com/on-site/active_record-postgres-constraints
  # TODO https://github.com/janko/sequel-activerecord_connection
  # TODO https://github.com/GeorgeKaraszi/ActiveRecordExtended
  # https://github.com/delonnewman/activerecord-setops
  # https://github.com/westonganger/active_snapshot
  # https://github.com/DmitryTsepelev/ar_lazy_preload
  s.add_dependency 'date_validator'
  s.add_dependency 'discard'
  # https://github.com/jrochkind/faster_s3_url
  # https://www.reddit.com/r/ruby/comments/j365oy/what_surprised_us_in_postgresqlschema_based/
  # https://www.reddit.com/r/rails/comments/j2xzir/does_hosting_streaming_video_get_pretty_expensive/
  s.add_dependency 'http_accept_language'
  s.add_dependency 'i18n-debug'
  # TODO https://github.com/prograils/lit
  s.add_dependency 'money-rails'
  s.add_dependency 'monogamy'
  s.add_dependency 'null-logger'
  s.add_dependency 'pg'
  # TODO https://github.com/floere/phony
  s.add_dependency 'pycall'
  s.add_dependency 'rails-i18n'
  s.add_dependency 'rails_select_on_includes'
  s.add_dependency 'rblineprof'
  s.add_dependency 'routes_lazy_routes'
  # s.add_dependency 'sequel-activerecord-adapter'
  # TODO https://github.com/gocardless/statesman
  # TODO https://github.com/doctolib/safe-pg-migrations
  s.add_dependency "stateful_enum"
  s.add_dependency 'store_base_sti_class'
  s.add_dependency 'mix_setting'
  s.add_dependency 'sunzistrano'
  s.add_dependency 'user_agent_parser'
end
