require 'mix_server/action_controller/metal'

ActionController::API.class_eval do
  prepend ActionController::WithMixServer
end
