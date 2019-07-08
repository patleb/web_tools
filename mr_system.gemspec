# Maintain your gem's version:
require_relative "./version"
version = MrSystem::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mr_system"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mr_system"
  s.summary     = "MrSystem"
  s.description = "MrSystem"
  s.license     = "MIT"

  s.files = Dir["{app,bin,config,db,lib}/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency "rails", "~> #{MrSystem::RAILS_VERSION::STRING}"
  s.add_dependency "ext_capistrano", version
  s.add_dependency "ext_minitest",   version
  s.add_dependency "ext_rake",       version
  s.add_dependency "ext_ruby",       version
  s.add_dependency "ext_sql",        version
  s.add_dependency "ext_whenever",   version
  s.add_dependency "mr_backup",      version
  s.add_dependency "mr_notifier",    version
  s.add_dependency "mr_setting",     version
  s.add_dependency "sun_cap",        version
  s.add_dependency "sunzistrano"
end
