require_dir __FILE__, 'base'
require 'ext_rails/action_controller/redirecting/with_string_url'

ActionController::Base.class_eval do
  class_attribute :local

  include ActiveSupport::LazyLoadHooks::Autorun
  include ActionController::Redirecting::WithStringUrl
  prepend self::BeforeRender
  prepend self::WithContext
  include self::WithMemoization

  ActiveSupport.run_load_hooks('ActionController', self, parent: true)
end
