require_rel 'base'

ActionController::Base.class_eval do
  include ActiveSupport::LazyLoadHooks::Autorun
  include self::WithRescue
  include self::WithContext

  def params!
    @_params_bang ||= params.to_unsafe_h.with_keyword_access
  end
  helper_method :params!
end
