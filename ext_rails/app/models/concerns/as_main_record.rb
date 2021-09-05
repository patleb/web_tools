module AsMainRecord
  extend ActiveSupport::Concern

  included do
    establish_main_connection
  end

  class_methods do
    def establish_main_connection
      env = :"main_#{Rails.env}"
      keys = %i(host port database username)
      main_config = ActiveRecord::Base.configurations.resolve(env).configuration_hash.slice(*keys)
      default_config = ActiveRecord::Base.configurations.resolve(Rails.env.to_sym).configuration_hash.slice(*keys)
      main_host, default_host = main_config.delete(:host), default_config.delete(:host)
      return establish_connection(env) unless main_config == default_config
      return if main_host == default_host
      return establish_connection(env) unless Host.domains.has_key? :server
      return if Host.domains[:server].find{ |name, _ip| name == main_host }&.last == default_host
      establish_connection(env)
    end
  end
end
