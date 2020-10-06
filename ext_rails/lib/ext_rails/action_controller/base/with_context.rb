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
  rescue NoMethodError => e
    render_500 NoMethodError.new("#{e.message}\nat #{e.backtrace.first}", e.name)
  end

  def without_time_zone(&block)
    ActiveRecord::Base.without_time_zone(&block)
  end

  def set_current_referer
    if request.get? && request.referer.present?
      if (uri = URI.parse(request.referer)).host == request.host && (uri.path != request.path)
        session[:referer] = uri.path
      end
    end
    Current.referer ||= session[:referer]
  end

  # TODO unit tests --> too much branches
  def set_current_value(name, permitted = [])
    Current[name] ||= begin
      param = "_#{name}"
      if (current_value = params.delete(param)).present?
        if permitted.none?{ |value| value.to_s == current_value }
          raise UnpermittedParameterValue.new([param])
        end
        if session?
          session[name] = current_value
        else
          current_value
        end
      else
        if session?
          if (current_value = session[name]).present? && permitted.none?{ |value| value.to_s == current_value }
            session[name] = get_current_value_default(name)
          else
            session[name] ||= get_current_value_default(name)
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
    locale = cookies["js.locale"]
    locale = locale.presence && I18n.available_locales.find{ |l| l.to_s == locale }
    locale = http_accept_language.compatible_language_from(I18n.available_locales) unless locale.present?
    locale
  end

  def default_time_zone
    Time.find_zone(cookies["js.time_zone"])&.name
  end
end
