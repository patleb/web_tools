require_relative '../datetime'

class RailsAdmin::Config::Model::Fields::Array::Datetime < RailsAdmin::Config::Model::Fields::Array
  include RailsAdmin::Config::Model::Fields::Datetime::Formatter

  def array_separator
    @array_separator ||= '<br>'.html_safe
  end

  def value
    super&.map{ |item| value_in_time_zone(item) }
  end

  def pretty_array
    (value || []).map{ |item| pretty_format_datetime(item) }
  end

  def export_array
    value&.map{ |item| export_format_datetime(item) }
  end

  def truncated_array_options
    { escape: false, max_items: 1 }
  end
end
