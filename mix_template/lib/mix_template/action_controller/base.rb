require_rel 'base'

ActionController::Base.class_eval do
  helper  MixTemplate::Engine.helpers
  include TemplatesHelper
  include self::WithPresenter
  include self::BeforeRender
  prepend self::BeforeRenderInstance

  def app_root_path
    @@_app_root_path ||= (main_app.try(:root_path) || '/')
  end
  helper_method :app_root_path
end
