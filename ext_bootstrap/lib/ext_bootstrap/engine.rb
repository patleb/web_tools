module ExtBootstrap
  class Engine < ::Rails::Engine
    ActiveSupport.on_load(:action_controller) do
      ::ActionController::Base.class_eval do
        helper ExtBootstrap::Engine.helpers
      end
    end
  end
end
