source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.5'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.2'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
end

gem 'baby_squeel', github: 'rzane/baby_squeel', branch: 'ar-521' # TODO https://github.com/rzane/baby_squeel/issues/97

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

### AFTER Gemfile ###

# Declare your gem's dependencies in mr_backend.gemspec.
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
gem 'ext_minitest', path: './ext_minitest'
gem 'ext_rake', path: './ext_rake'
gem 'ext_ruby', path: './ext_ruby'
gem 'ext_sql', path: './ext_sql'
gem 'ext_whenever', path: './ext_whenever'
gem 'mr_backup', path: './mr_backup'
gem 'mr_core', path: './mr_core'
gem 'mr_global', path: './mr_global'
gem 'mr_notifier', path: './mr_notifier'
gem 'mr_setting', path: './mr_setting'
gem 'mr_rescue', path: './mr_rescue'
gem 'mr_template', path: './mr_template'
gem 'mr_throttler', path: './mr_throttler'
gem 'sun_cap', path: './sun_cap'
gem 'sunzistrano', path: './sunzistrano'
