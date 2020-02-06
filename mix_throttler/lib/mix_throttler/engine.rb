require "mix_throttler/configuration"

module MixThrottler
  class Engine < ::Rails::Engine
    require 'rack/attack'
    require 'mix_global'

    config.before_initialize do |app|
      app.config.middleware.use Rack::Attack
    end
  end
end
