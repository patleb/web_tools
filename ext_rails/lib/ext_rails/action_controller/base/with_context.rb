module ActionController::Base::WithContext
  extend ActiveSupport::Concern

  class UnpermittedParameterValue < ::ActionController::UnpermittedParameters; end

  included do
    prepend_before_action :set_current
    around_action :with_context
  end

  def rescue_with_handler(exception)
    with_context do
      super
    end
  end

  def session?
    true
  end

  protected

  def set_current
    Current.controller = self
    Current.session_id ||= session.try(:id)
    Current.request_id ||= request.uuid
    set_current_referer
    set_current_value(:locale, I18n.available_locales)
    set_current_value(:time_zone)
  end

  def with_context
    I18n.with_locale(Current.locale) do
      Time.use_zone(Current.time_zone.presence) do
        yield
      end
    end
  rescue NoMethodError => e # prevent infinite loop
    render_500 NoMethodError.new("NoMethodError: undefined method\nat #{e.backtrace.first}", e.name)
  end

  def without_time_zone(&block)
    ActiveRecord::Base.without_time_zone(&block)
  end

  def set_current_referer
    if request.get? && request.referer.present?
      if (uri = URI.parse(request.referer)).host == request.host && ((path = uri.path) != request.path)
        unless defined?(MixUser) && path.start_with?('/users/')
          session[:referer] = path
        end
      end
    end
    Current.referer ||= session[:referer]
    Current.referer ||= send(:get_root_path) if respond_to?(:get_root_path, true)
  end

  def set_current_value(name, permitted = [])
    Current[name] ||= begin
      param = "_#{name}"
      js_name = "js.#{name}"
      if (current_value = params.delete(param)).present?
        if permitted.none?{ |value| value.to_s == current_value }
          raise UnpermittedParameterValue.new([param])
        end
        if session?
          cookies[js_name] = current_value
        else
          current_value
        end
      else
        if session?
          if (current_value = cookies[js_name]).present? && permitted.none?{ |value| value.to_s == current_value }
            cookies[js_name] = get_current_value_default(name)
          else
            cookies[js_name] ||= get_current_value_default(name)
          end
        else
          get_current_value_default(name)
        end
      end
    end
  end

  private

  def get_current_value_default(name)
    if (value = send("default_#{name}")).present?
      value.to_s
    end
  end

  def default_locale
    locale = I18n.available_locales.find{ |l| l.to_s == locale }
    locale.presence || http_accept_language.compatible_language_from(I18n.available_locales)
  end

  def default_time_zone
    Time.find_zone(cookies["js.time_zone"])&.name
  end
end
