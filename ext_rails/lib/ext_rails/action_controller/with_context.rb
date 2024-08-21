module ActionController::WithContext
  extend ActiveSupport::Concern

  included do
    helper_method :application_path
    helper_method :root_path
    helper_method :back_path
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
    Current.session_id = session[:session_id]
    Current.request_id = request.uuid
    set_current_locale
    set_current_timezone
  end

  def set_current_locale
    locale = params[:_locale].presence || request.headers['X-Locale'].presence || cookies[:_locale].presence
    unless locale && I18n.available_locales.any?{ |l| l.to_s == locale }
      locale = session[:locale].presence || http_accept_language.compatible_language_from(I18n.available_locales)
    end
    locale ||= I18n.default_locale
    session[:locale] = cookies[:_locale] = locale.to_s
    Current.locale = locale.to_sym
  end

  def set_current_timezone
    timezone = params[:_timezone].presence || request.headers['X-Timezone'].presence || cookies[:_timezone].presence
    timezone = timezone.to_i? ? timezone.to_i : timezone
    unless (timezone = Time.find_zone(timezone)&.name)
      timezone = session[:timezone].presence
    end
    timezone ||= Rails.application.config.time_zone
    Current.timezone = session[:timezone] = cookies[:_timezone] = timezone
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
    MixRescue.config.rescue_500 ? render_500(exception) : raise(exception)
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

  def _back
    params[:_back].presence || request.headers['X-Back'].presence || request.referer.presence
  end
end
