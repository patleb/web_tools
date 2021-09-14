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
    set_current_value(:locale, I18n.available_locales.map(&:to_s))
    set_current_value(:time_zone)
  end

  def with_context
    I18n.with_locale(Current.locale) do
      Time.use_zone(Current.time_zone.presence) do
        yield
      end
    end
  rescue NoMethodError => e # prevent infinite loop
    backtrace = e.backtrace.first(ExtRuby.config.backtrace_log_lines)
    message = "undefined method name[#{e.name}] maybe[#{e.corrections.first}]\nat #{backtrace.join("\n")}"
    render_500 NoMethodError.new(message, e.name)
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

  def set_current_value(name, allowed_values = nil)
    Current[name] ||= begin
      param = "_#{name}"
      js_name = "js.#{name}"
      if (value = params.delete(param)).present?
        value = value.cast
        if allowed_values&.none?{ |v| v == value }
          raise UnpermittedParameterValue.new([param])
        elsif session?
          cookies[js_name] = value
        else
          value
        end
      elsif session?
        if (value = cookies[js_name]).present?
          value = value.cast
          if allowed_values&.none?{ |v| v == value }
            raise UnpermittedParameterValue.new([param])
          end
          value
        else
          cookies[js_name] = default_current_value(name)
        end
      else
        default_current_value(name)
      end
    end
  end

  private

  def default_current_value(name)
    send("default_#{name}")&.cast
  end

  def default_locale
    locale = cookies["js.locale"]
    locale = I18n.available_locales.find{ |l| l.to_s == locale }
    locale.presence || http_accept_language.compatible_language_from(I18n.available_locales)
  end

  def default_time_zone
    Time.find_zone(cookies["js.time_zone"])&.name
  end
end
