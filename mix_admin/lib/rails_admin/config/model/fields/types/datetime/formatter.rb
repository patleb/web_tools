module RailsAdmin::Config::Model::Fields::Datetime::Formatter
  extend ActiveSupport::Concern

  included do
    register_instance_option :pretty_format do
      :long
    end

    register_instance_option :i18n_scope do
      [:datetime, :formats, :pretty]
    end

    register_instance_option :strftime_format, memoize: :locale do
      I18n.t(pretty_format, scope: i18n_scope)
    end
  end

  def value_in_time_zone(value)
    case value
    when DateTime, Date, Time
      value.in_time_zone
    else
      value
    end
  end

  def pretty_format_datetime(value)
    I18n.l(value, format: strftime_format)
  end

  def export_format_datetime(value)
    value&.iso8601
  end
end
