require 'ext_rails/action_controller/redirecting/with_query_params'

ActionController::API.class_eval do
  class_attribute :local

  include ActiveSupport::LazyLoadHooks::Autorun
  include ActionController::MimeResponds
  include ActionController::Redirecting::WithStringUrl

  ActiveSupport.run_load_hooks('ActionController', self, parent: true)
end
