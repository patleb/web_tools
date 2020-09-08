require 'ext_rails/action_controller/base/with_context'
require 'ext_rails/action_controller/redirecting/with_query_params'

ActionController::Base.class_eval do
  include ActiveSupport::LazyLoadHooks::Autorun
  include ActionController::Redirecting::WithQueryParams
  include self::WithContext

  def params!
    @_params_bang ||= params.to_unsafe_h.with_keyword_access
  end
  helper_method :params!
end
