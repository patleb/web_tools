class LibController < ActionController::Base
  before_render :set_meta_values

  private

  def set_meta_values
    (@meta ||= {}).merge!(root: root_path, app: (title = Rails.application.title), title: title, description: title)
  end
end
