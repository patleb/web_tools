require_rel 'base'

ActionController::Base.class_eval do
  helper  MixTemplate::Engine.helpers
  include MixTemplate::ViewHelper
  include self::WithPresenter
  include self::BeforeRender
  prepend self::BeforeRenderInstance
end
