require 'ext_rails/action_controller/redirecting/with_string_url'
require 'ext_rails/action_controller/with_context'
require 'ext_rails/action_controller/with_memoization'

ActionController::API.class_eval do
  class_attribute :local

  include ActiveSupport::LazyLoadHooks::Autorun
  include ActionController::MimeResponds
  include ActionController::Redirecting::WithStringUrl
  include ActionController::WithContext
  include ActionController::WithMemoization

  ActiveSupport.run_load_hooks('ActionController', self, parent: true)
end
