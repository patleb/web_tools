require_rel 'base'

ActionController::Base.class_eval do
  helper  MixTemplate::Engine.helpers
  include TemplatesHelper
  include self::WithPresenter
  include self::BeforeRender
  prepend self::BeforeRenderInstance

  def app_root_path
    if ActionController::Base.class_variable_defined? :@@_app_root_path
      ActionController::Base.class_variable_get(:@@_app_root_path)
    else
      ActionController::Base.class_variable_set(:@@_app_root_path, main_app.try(:root_path) || '/')
    end
  end
  helper_method :app_root_path
end
