require 'mix_server/action_controller/metal'

ActionController::Base.class_eval do
  prepend ActionController::WithLogErrors
end
