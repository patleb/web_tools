source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read('.ruby-version').strip

# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'shakapacker', '~> 6.1.1'

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'

group :development, :test do
  gem 'ext_minitest', path: './ext_minitest'
  # gem 'ext_minitest', github: 'patleb/web_tools'
  # gem 'ext_minitest', path: '~/projects/web_tools'
end

group :development do
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  # gem 'rack-mini-profiler', '~> 2.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# gem 'web_tools', github: 'patleb/web_tools'
# gem 'web_tools', path: '~/projects/web_tools'

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

gem 'ext_bootstrap', path: './ext_bootstrap'
gem 'ext_capistrano', path: './ext_capistrano'
gem 'ext_coffee', path: './ext_coffee'
gem 'ext_rails', path: './ext_rails'
gem 'ext_ruby', path: './ext_ruby'
gem 'ext_sass', path: './ext_sass'
gem 'ext_webpacker', path: './ext_webpacker'
gem 'ext_whenever', path: './ext_whenever'
gem 'mix_admin', path: './mix_admin'
gem 'mix_certificate', path: './mix_certificate'
gem 'mix_monit', path: './mix_monit'
gem 'mix_email', path: './mix_email'
gem 'mix_file', path: './mix_file'
gem 'mix_flash', path: './mix_flash'
gem 'mix_geo', path: './mix_geo'
gem 'mix_global', path: './mix_global'
gem 'mix_rpc', path: './mix_rpc'
gem 'mix_search', path: './mix_search'
gem 'mix_server', path: './mix_server'
gem 'mix_setting', path: './mix_setting'
gem 'mix_job', path: './mix_job'
gem 'mix_log', path: './mix_log'
gem 'mix_page', path: './mix_page'
gem 'mix_rescue', path: './mix_rescue'
gem 'mix_task', path: './mix_task'
gem 'mix_template', path: './mix_template'
gem 'mix_user', path: './mix_user'
gem 'sunzistrano', path: './sunzistrano'

gem 'net-ssh', '6.1.0'
gem 'pundit', '2.1.1'
gem 'ruby-pg-extras', '3.2.5'

eval File.read('Gemfile.private') if File.exists? 'Gemfile.private'
