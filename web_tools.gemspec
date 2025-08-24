# Maintain your gem's version:
require_relative "./version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "web_tools"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/web_tools"
  s.summary     = "WebTools"
  s.description = "WebTools"
  s.license     = "LGPL-2.1"

  s.files = Dir[".multipass/key", ".multipass/key.pub", "lib/**/*", "LICENSE", "README.md"]

  s.add_dependency "ext_coffee",      version
  s.add_dependency "ext_css",         version
  s.add_dependency "ext_minitest",    version
  s.add_dependency "ext_rails",       version
  s.add_dependency "ext_rice",        version
  s.add_dependency "ext_ruby",        version
  s.add_dependency "ext_shakapacker", version
  s.add_dependency "ext_whenever",    version
  s.add_dependency "mix_admin",       version
  s.add_dependency "mix_certificate", version
  s.add_dependency "mix_file",        version
  s.add_dependency "mix_flash",       version
  s.add_dependency "mix_geo",         version
  s.add_dependency "mix_global",      version
  s.add_dependency "mix_job",         version
  s.add_dependency "mix_page",        version
  s.add_dependency "mix_rpc",         version
  s.add_dependency "mix_search",      version
  s.add_dependency "mix_server",      version
  s.add_dependency "mix_setting"
  s.add_dependency "mix_task",        version
  s.add_dependency "mix_user",        version
  s.add_dependency "sunzistrano"
end
