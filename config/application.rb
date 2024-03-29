require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
require 'web_tools/admin'
require 'web_tools/application'
require 'web_tools/private' if File.exists? 'lib/web_tools/private.rb'

module WebTools
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1
    # Rails 7.0 https://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#key-generator-digest-class-changing-to-use-sha256
    config.active_support.hash_digest_class = OpenSSL::Digest::SHA256

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # config.i18n.default_locale = :en
    config.active_record.belongs_to_required_by_default = false
    config.active_record.cache_versioning = false
    config.cache_store = :global_store

    initializer 'app.libraries' do
      Rice.require_ext
      # require_relative '../app/libraries/some_override'
    end
  end
end
