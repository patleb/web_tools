$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require 'sunzistrano/version'

Gem::Specification.new do |s|
  s.name          = 'sunzistrano'
  s.version       = Sunzistrano::VERSION
  s.authors       = ['Patrice Lebel']
  s.email         = ['patleb@users.noreply.github.com']
  s.homepage      = 'http://github.com/patleb/sunzistrano'
  s.summary       = %q{Server provisioning utility for minimalists}
  s.description   = %q{Server provisioning utility for minimalists}
  s.license       = 'MIT'

  s.files         = Dir["{bin,config,lib}/**/*", "MIT-LICENSE", "README.md"]
  s.executables   = ["sun"]

  s.add_dependency "sshkit"
  s.add_dependency 'rainbow'
  s.add_dependency 'bcrypt'
  s.add_dependency 'ext_ruby'
end
