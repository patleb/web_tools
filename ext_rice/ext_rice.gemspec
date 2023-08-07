$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_rice"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_rice"
  s.summary     = "ExtRice"
  s.description = "ExtRice"
  s.license     = "AGPL-3.0"

  s.files = Dir["{lib,vendor}/**/*", "LICENSE", "README.md"]

  s.add_dependency 'ext_ruby', version
  s.add_dependency 'rice', '~> 4.1.0'
  s.add_dependency 'numo-narray'
end
# Ubuntu 18.04
# sudo add-apt-repository ppa:ubuntu-toolchain-r/test
# sudo apt-get update
# sudo apt install gcc-10 gcc-10-base gcc-10-doc g++-10
# sudo apt install libstdc++-10-dev libstdc++-10-doc
# sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 30
# sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 30
