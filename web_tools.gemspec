# Maintain your gem's version:
require_relative "./version"
version = WebTools::VERSION::STRING # TODO rename to web_tools_ce with WebTools

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "web_tools"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/web_tools"
  s.summary     = "WebTools"
  s.description = "WebTools"
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency "ext_bootstrap",  version
  s.add_dependency "ext_capistrano", version
  s.add_dependency "ext_minitest",   version
  s.add_dependency "ext_pjax",       version
  s.add_dependency "ext_rake",       version
  s.add_dependency "ext_ruby",       version
  s.add_dependency "ext_vue",        version
  s.add_dependency "ext_webpacker",  version
  s.add_dependency "ext_whenever",   version
  s.add_dependency "mix_admin",      version
  s.add_dependency "mix_backup",     version
  s.add_dependency "ext_rails",       version
  s.add_dependency "mix_global",     version
  s.add_dependency "mix_setting"
  s.add_dependency "mix_sql",        version
  s.add_dependency "mix_page",       version
  s.add_dependency "mix_rescue",     version
  s.add_dependency "mix_template",   version
  s.add_dependency "mix_user",       version
  s.add_dependency "sunzistrano"
end
