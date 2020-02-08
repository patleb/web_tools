$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require_relative "./../version"
version = WebTools::VERSION::STRING

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ext_minitest"
  s.version     = version
  s.authors     = ["Patrice Lebel"]
  s.email       = ["patleb@users.noreply.github.com"]
  s.homepage    = "https://github.com/patleb/ext_minitest"
  s.summary     = "ExtMinitest"
  s.description = "ExtMinitest"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "README.md"]

  s.add_dependency 'minitest', '>= 5.11'
  s.add_dependency 'minitest-hooks'
  s.add_dependency 'minitest-spec-rails'
  s.add_dependency 'minitest-reporters', '>= 1.3'
  s.add_dependency 'minitest-retry'
  s.add_dependency 'maxitest'
  s.add_dependency 'mocha', '>= 1.3'
  s.add_dependency 'webmock'
  s.add_dependency 'shoulda-matchers', '>= 3.1'
  s.add_dependency 'rails-controller-testing'
  s.add_dependency 'safe_dup'
  s.add_dependency 'safe_clone'
  s.add_dependency 'full_dup'
  s.add_dependency 'full_clone'
  s.add_dependency 'hash_dot'
  s.add_dependency 'to_words'
  s.add_dependency 'chronic'
  s.add_dependency 'cod'
  s.add_dependency 'diffy'
  s.add_dependency 'vcr'
  s.add_dependency 'ext_ruby', version
  # TODO https://github.com/rubocop-hq/rubocop-minitest
end
