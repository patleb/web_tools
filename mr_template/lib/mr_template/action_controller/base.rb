require_rel 'base'

ActionController::Base.class_eval do
  helper  MrTemplate::Engine.helpers
  include MrTemplate::ViewHelper
  include self::WithPresenter
  include self::BeforeRender
  prepend self::BeforeRenderInstance
end
