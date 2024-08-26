require_dir __FILE__, 'base'
require 'ext_rails/action_controller/metal'

ActionController::Base.class_eval do
  prepend ActionController::WithExtRails
  prepend self::BeforeRender

  ActiveSupport.run_load_hooks('ActionController', self, parent: true)
end
