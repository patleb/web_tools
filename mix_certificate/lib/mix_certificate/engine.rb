require 'ext_rails'
require 'mix_certificate/configuration'

ACME_CHALLENGE = '.well-known/acme-challenge'.freeze

module MixCertificate
  require 'openssl'
  require 'acme-client'

  class Engine < ::Rails::Engine
    initializer 'mix_certificate.append_migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_certificate.prepend_routes', before: 'ext_rails.append_routes' do |app|
      app.routes.prepend do
        get "/#{ACME_CHALLENGE}/:token" => 'certificates#show', type: 'Certificates::LetsEncrypt'
      end
    end

    initializer 'mix_certificate.backup' do
      ExtRails.config.temporary_tables << 'lib_certificates'
    end

    ActiveSupport.on_load(:active_record) do
      MixLog.config.ided_paths[%r{/(#{ACME_CHALLENGE})/([\w-]+)}] = '/\1/*'
    end
  end
end
