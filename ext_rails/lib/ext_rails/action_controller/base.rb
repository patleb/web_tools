require_dir __FILE__, 'base'
require 'ext_rails/action_controller/redirecting/with_query_params'

ActionController::Base.class_eval do
  class_attribute :local

  include ActiveSupport::LazyLoadHooks::Autorun
  include ActionController::Redirecting::WithStringUrl
  include self::WithContext
  include self::WithMemoization
  prepend self::BeforeRender

  ActiveSupport.run_load_hooks('ActionController', self, parent: true)
end
