class LibController < ActionController::Base
  before_render :set_meta_values

  attr_accessor :template_virtual_path
  helper_method :template_virtual_path

  protected

  def application_path
    self.class.cvar(:@@application_path){ main_app.try(:root_path) || '/' }
  end
  helper_method :application_path

  private

  def set_meta_values
    (@meta ||= {}).merge!(
      root: respond_to?(:root_path) ? root_path : application_path,
      app: Rails.application.title,
      title: Rails.application.title,
      description: Rails.application.title,
    )
  end
end
