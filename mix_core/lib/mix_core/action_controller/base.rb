require 'mix_core/action_controller/base/with_context'

ActionController::Base.class_eval do
  include ActiveSupport::LazyLoadHooks::Autorun
  include self::WithContext

  def params!
    @_params_bang ||= params.to_unsafe_h.with_keyword_access
  end
  helper_method :params!
end
