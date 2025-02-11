module ActionController::WithContext
  extend ActiveSupport::Concern

  included do
    if respond_to? :helper_method
      helper_method :application_path
      helper_method :root_path
      helper_method :back_path
    end
  end

  def rescue_with_handler(exception)
    with_context do
      super
    end
  end

  protected

  def application_path
    self.class.ivar(:@application_path){ main_app.try(:root_path) || '/' }
  end

  def root_path
    application_path
  end

  def back_path
    path = _back_path
    return root_path unless path && _url_host_allowed?(path)
    path
  end

  def redirect_back(fallback_location: root_path, **)
    super(fallback_location: fallback_location, **)
  end

  def redirect_back_or_to(fallback_location = root_path, allow_other_host: _allow_other_host, **)
    path = _back_path
    if path && (allow_other_host || _url_host_allowed?(path))
      redirect_to(path, allow_other_host: allow_other_host, **)
    elsif fallback_location == request.original_fullpath
      redirect_to(application_path, **)
    else
      redirect_to(fallback_location, **)
    end
  end

  def browser_bot?
    user_agent[UA[:name]] == 'HeadlessChrome' || user_agent[UA[:hw_brand]] == 'Spider'
  end

  def user_agent
    @user_agent ||= USER_AGENT_PARSER.parse(request.user_agent).browser_array
  end

  def set_current
    Current.controller = self
    Current.session_id = session[:session_id] if respond_to? :session
    Current.request_id = request.uuid
    set_current_locale
    set_current_timezone
    set_current_theme
  end

  def set_current_locale
    _set_current :locale, symbol: true do |locale|
      next locale if locale && I18n.available_locales.any?{ |l| l.to_s == locale }
      session[:locale].presence || http_accept_language.compatible_language_from(I18n.available_locales)
    end
  end

  def default_locale
    I18n.default_locale
  end

  def set_current_timezone
    _set_current :timezone do |timezone|
      timezone = timezone.to_i? ? timezone.to_i : timezone
      Time.find_zone(timezone)&.name || session[:timezone].presence
    end
  end

  def default_timezone
    Rails.application.config.time_zone
  end

  def set_current_theme
    _set_current :theme, symbol: true do |theme|
      ExtRails.config.themes.has_key?(theme) && theme
    end
  end

  def default_theme
    ExtRails.config.theme
  end

  def with_context
    I18n.with_locale(Current.locale) do
      Time.use_zone(Current.timezone.presence) do
        yield
      end
    end
  end

  def without_timezone(&block)
    old_value = Current.timezone
    Current.timezone = 'UTC'
    ActiveRecord::Base.without_timezone(&block)
  ensure
    Current.timezone = old_value
  end

  private

  def process_action(...)
    set_current
    with_context do
      super
    end
  end

  def _set_current(name, symbol: false)
    if respond_to? :session
      _name = :"_#{name}"
      xname = "X-#{name.to_s.camelize}"
      value = params[_name].presence || request.headers[xname].presence || cookies[_name].presence
      value = yield(value) || send("default_#{name}")
      session[name] = cookies[_name] = value.to_s
      Current[name] = symbol ? value.to_sym : value
    else
      Current[name] = send("default_#{name}")
    end
  end

  def _back_path
    path = @_back.presence || params[:_back].presence || request.headers['X-Back'].presence || request.referer.presence
    path = path&.delete_prefix(ExtRails::Routes.base_url)
    path unless path == request.original_fullpath
  end
end
