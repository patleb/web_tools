require_relative './staging'

if ENV['DEVELOPMENT'].to_b
  Rails.application.configure do
    # In the development environment your application's code is reloaded on
    # every request. This slows down response time but is perfect for development
    # since you don't have to restart the web server when you make code changes.
    config.cache_classes = false

    # Compress JavaScripts and CSS.
    config.assets.js_compressor = nil
    config.assets.css_compressor = nil

    # Do not fallback to assets pipeline if a precompiled asset is missed.
    config.assets.compile = true

    # Debug mode disables concatenation and preprocessing of assets.
    # This option may cause significant delays in view rendering with a large
    # number of complex assets.
    config.assets.debug = false

    # Suppress logger output for asset requests.
    config.assets.quiet = true
  end
end
