require 'ext_rails/action_controller/base/before_render'
require 'ext_rails/action_controller/redirecting/with_string_url'

ActionController::Base.class_eval do
  class_attribute :local

  include ActiveSupport::LazyLoadHooks::Autorun
  include ActionController::Redirecting::WithStringUrl
  include ActionController::WithContext
  include ActionController::WithMemoization
  prepend self::BeforeRender

  ActiveSupport.run_load_hooks('ActionController', self, parent: true)
end
