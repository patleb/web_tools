class LibController < ActionController::Base
  before_render :set_meta_values

  attr_accessor :template_virtual_path
  helper_method :template_virtual_path

  protected

  def application_path
    self.class.ivar(:@application_path){ main_app.try(:root_path) || '/' }
  end
  helper_method :application_path

  def root_path
    application_path
  end
  helper_method :root_path

  def back_path
    back = _back
    return root_path unless back && _url_host_allowed?(back)
    back
  end
  helper_method :back_path

  def redirect_back(fallback_location: root_path, **)
    super(fallback_location: fallback_location, **)
  end

  def redirect_back_or_to(fallback_location = root_path, allow_other_host: _allow_other_host, **)
    back = _back
    if back && (allow_other_host || _url_host_allowed?(back))
      redirect_to(back, allow_other_host: allow_other_host, **)
    else
      redirect_to(fallback_location, **)
    end
  end

  private

  def set_meta_values
    (@meta ||= {}).merge!(root: root_path, app: (title = Rails.application.title), title: title, description: title)
  end

  def _back
    params[:_back].presence || request.headers['X-Back'].presence || request.referer.presence
  end
end
