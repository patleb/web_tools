require 'ext_rails/action_controller/metal'

ActionController::API.class_eval do
  include ActionController::Cookies
  include ActionController::MimeResponds
  prepend ActionController::WithExtRails

  ActiveSupport.run_load_hooks('ActionController', self, parent: true)
end
