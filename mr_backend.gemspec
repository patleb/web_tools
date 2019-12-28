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
