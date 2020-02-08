source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
# gem 'webpacker'
# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'

group :development, :test do
  gem 'ruby-debug-ide'
  gem 'debase'

  gem 'ext_minitest', path: './ext_minitest'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

### AFTER Gemfile ###

# Declare your gem's dependencies in web_tools.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
# gem 'byebug', group: [:development, :test]

gem 'ext_capistrano', path: './ext_capistrano'
gem 'ext_rake', path: './ext_rake'
gem 'ext_ruby', path: './ext_ruby'
gem 'ext_webpacker', path: './ext_webpacker'
gem 'ext_whenever', path: './ext_whenever'
gem 'mix_backup', path: './mix_backup'
gem 'mix_core', path: './mix_core'
gem 'mix_global', path: './mix_global'
gem 'mix_notifier', path: './mix_notifier'
gem 'mix_setting', path: './mix_setting'
gem 'mix_sql', path: './mix_sql'
gem 'mix_rescue', path: './mix_rescue'
gem 'mix_template', path: './mix_template'
gem 'mix_throttler', path: './mix_throttler'
gem 'sun_cap', path: './sun_cap'
gem 'sunzistrano', path: './sunzistrano'
