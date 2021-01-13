require 'ext_rails'
require 'mix_credential/configuration'

ACME_CHALLENGE = '.well-known/acme-challenge'.freeze

module MixCredential
  require 'openssl'
  require 'acme-client'

  class Engine < ::Rails::Engine
    initializer 'mix_credential.append_migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_credential.prepend_routes', before: 'ext_rails.append_routes' do |app|
      app.routes.prepend do
        get "/#{ACME_CHALLENGE}/:token" => 'credentials#show', type: 'Credentials::LetsEncrypt'
      end
    end

    ActiveSupport.on_load(:active_record) do
      MixLog.config.ided_paths[%r{/(#{ACME_CHALLENGE})/([\w-]+)}] = '/\1/*'
    end
  end
end
