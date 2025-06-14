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
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
require_shakapacker do
  Bundler.require(*Rails.groups)
end

module WebTools
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(minitest tasks web_tools))

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

    ExtRails.configure do |config|
      # config.sql_debug = false
    end

    initializer 'app.libraries' do
      # require_relative '../app/libraries/some_override'
    end

    initializer 'app.backtrace_silencers' do
      # You can add backtrace silencers for libraries that you're using but don't wish to see in your backtraces.
      # Rails.backtrace_cleaner.add_silencer { |line| /my_noisy_library/.match?(line) }

      # You can also remove all the silencers if you're trying to debug a problem that might stem from framework code
      # by setting BACKTRACE=1 before calling your invocation, like "BACKTRACE=1 ./bin/rails runner 'MyClass.perform'".
      # ENV["BACKTRACE"] = 'true'
    end

    initializer 'app.mime_types' do
      # Add new mime types for use in respond_to blocks:
      # Mime::Type.register "text/richtext", :rtf
    end

    initializer 'app.permissions_policy' do
      # Define an application-wide HTTP permissions policy. For further
      # information see: https://developers.google.com/web/updates/2018/06/feature-policy

      # Rails.application.config.permissions_policy do |policy|
      #   policy.camera      :none
      #   policy.gyroscope   :none
      #   policy.microphone  :none
      #   policy.usb         :none
      #   policy.fullscreen  :self
      #   policy.payment     :self, "https://secure.example.com"
      # end
    end
  end
end
