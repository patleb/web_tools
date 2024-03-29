$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mix_admin"
  s.version     = version
  s.authors     = ['Erik Michaels-Ober', 'Bogdan Gaza', 'Petteri Kaapa', 'Benoit Benezech', 'Mitsuhiro Shibuya']
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/mix_admin"
  s.summary     = 'Admin for Rails'
  s.description = 'RailsAdmin is a Rails engine that provides an easy-to-use interface for managing your data.'
  s.licenses    = ["AGPL-3.0", "MIT"]

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md"]

  # TODO s.add_dependency 'amoeba', '~> 3.0' # https://github.com/moiristo/deep_cloneable
  # TODO s.add_dependency 'prawn'
  s.add_dependency 'kaminari', '>= 0.14', '< 2.0' # TODO https://github.com/basecamp/geared_pagination
  s.add_dependency 'mix_global', version
  s.add_dependency 'mix_user',   version

  s.add_development_dependency 'ext_minitest', version
end
# https://juanitofatas.com/optimization_techniques_by_benchmark_winners
# TODO rails_admin commit --> 6e4a5a51 M.Shibuya on 2019-02-09 at 5:18 a.m.
