module ActionController::WithContext
  extend ActiveSupport::Concern

  included do
    if respond_to? :helper_method
      helper_method :application_path
      helper_method :root_path
      helper_method :back_path
    end
  end

  def rescue_with_handler(...)
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
    back = _back
    return root_path unless back && _url_host_allowed?(back)
    back
  end

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

  def with_context
    I18n.with_locale(Current.locale) do
      Time.use_zone(Current.timezone.presence) do
        yield
      end
    end
  rescue NoMethodError => e # prevent infinite loop
    backtrace = e.backtrace.first(ExtRuby.config.backtrace_log_lines)
    instead = e.corrections.first rescue nil
    message = instead ? "undefined method [#{e.name}], did you mean? [#{instead}]" : "undefined method [#{e.name}]"
    message = [message, e.message, "at #{backtrace.join("\n")}"].join! "\n"
    exception = NoMethodError.new(message, e.name)
    MixServer.config.rescue_500 ? render_500(exception) : raise(exception)
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

  def _back
    params[:_back].presence || request.headers['X-Back'].presence || request.referer.presence
  end
end
