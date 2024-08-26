require 'ext_rails/action_controller/metal'

ActionController::API.class_eval do
  prepend ActionController::WithExtRails
  include ActionController::MimeResponds

  ActiveSupport.run_load_hooks('ActionController', self, parent: true)
end
