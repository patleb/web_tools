require 'ext_ruby'
require 'ext_coffee/configuration'

module ExtCoffee
  class Engine < Rails::Engine
    config.before_initialize do |app|
      app.config.content_security_policy_nonce_generator = -> (request) do
        if request.headers['X-Referrer'].present?
          request.headers['X-Xhr-Nonce']
        elsif request.headers['Turbolinks-Referrer'].present?
          request.headers['X-Turbolinks-Nonce']
        else
          SecureRandom.base64(16)
        end
      end
    end

    ActiveSupport.on_load(:action_controller_base) do
      require 'ext_coffee/action_controller/base/with_xhr_redirect'
      require 'ext_coffee/turbolinks/v5.2.0/redirection'
      include Turbolinks::Redirection
    end
  end
end
