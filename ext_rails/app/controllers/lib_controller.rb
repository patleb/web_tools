class LibController < ActionController::Base
  before_render :set_meta_values

  private

  def set_meta_values
    title = Rails.application.title
    (@meta ||= {}).merge!(
      root: root_path,
      app: title,
      title: title,
      description: title
    )
  end
end
