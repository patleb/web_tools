# Maintain your gem's version:
require_relative "./version"
version = MixBackend::VERSION::STRING # TODO rename to mix_backend_ce with MixBackend

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mix_backend"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mix_backend"
  s.summary     = "MixBackend"
  s.description = "MixBackend"
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency "ext_capistrano", version
  s.add_dependency "ext_minitest",   version
  s.add_dependency "ext_rake",       version
  s.add_dependency "ext_ruby",       version
  s.add_dependency "ext_webpacker",  version
  s.add_dependency "ext_whenever",   version
  s.add_dependency "mix_backup",     version
  s.add_dependency "mix_core",       version
  s.add_dependency "mix_global",     version
  s.add_dependency "mix_notifier",   version
  s.add_dependency "mix_setting"
  s.add_dependency "mix_sql",        version
  s.add_dependency "mix_rescue",     version
  s.add_dependency "mix_template",   version
  s.add_dependency "mix_throttler",  version
  s.add_dependency "sun_cap",        version
  s.add_dependency "sunzistrano"
end
