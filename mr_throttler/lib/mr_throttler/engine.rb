require "mr_throttler/configuration"

module MrThrottler
  class Engine < ::Rails::Engine
    require 'rack/attack'
    require 'mr_global'

    config.before_initialize do |app|
      app.config.middleware.use Rack::Attack
    end
  end
end
