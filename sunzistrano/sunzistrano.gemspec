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
  s.licenses      = ["GPL-3.0", "MIT"]

  s.files         = Dir["{bin,config,lib}/**/*", "LICENSE", "README.md"]
  s.executables   = ["sun"]

  s.add_dependency 'mix_setting'
end
