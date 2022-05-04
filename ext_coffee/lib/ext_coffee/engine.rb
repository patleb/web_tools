require 'ext_ruby'
require 'ext_coffee/configuration'

module ExtCoffee
  class Engine < ::Rails::Engine
    require 'turbolinks'

    config.before_initialize do |app|
      app.config.content_security_policy_nonce_generator = -> (request) do
        if request.env['HTTP_TURBOLINKS_REFERRER'].present?
          request.env['HTTP_X_TURBOLINKS_NONCE']
        else
          SecureRandom.base64(16)
        end
      end
    end
  end
end
