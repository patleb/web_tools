require_relative '../boolean'

class RailsAdmin::Config::Model::Fields::Array::Boolean < RailsAdmin::Config::Model::Fields::Array
  include RailsAdmin::Config::Model::Fields::Boolean::Formatter

  def array_separator
    @array_separator ||= '&nbsp;'.html_safe
  end

  def pretty_array
    (value || []).map{ |item| pretty_format_boolean(item) }
  end

  def export_array
    value&.map{ |item| export_format_boolean(item) }
  end

  def truncated_array_options
    { escape: false, max_items: section.truncate_length / 3 }
  end
end
