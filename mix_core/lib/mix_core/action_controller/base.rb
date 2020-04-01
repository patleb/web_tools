require_rel 'base'

ActionController::Base.class_eval do
  include ActiveSupport::LazyLoadHooks::Autorun
  include self::WithRescue
  include self::WithContext

  def self.module_name
    @module_name ||= name.deconstantize.full_underscore
  end

  def module_name
    self.class.module_name
  end
  helper_method :module_name

  def params!
    @_params_bang ||= params.to_unsafe_h.with_keyword_access
  end
  helper_method :params!
end
