require 'ext_rails/action_controller/base/with_context'
require 'ext_rails/action_controller/redirecting/with_query_params'

ActionController::Base.class_eval do
  class_attribute :local

  include ActiveSupport::LazyLoadHooks::Autorun
  include ActionController::Redirecting::WithQueryParams
  include self::WithContext
end
