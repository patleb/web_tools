require 'ext_rails/action_controller/redirecting/with_query_params'

ActionController::API.class_eval do
  include ActiveSupport::LazyLoadHooks::Autorun
  include ActionController::MimeResponds
  include ActionController::Redirecting::WithQueryParams
end
