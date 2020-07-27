require_relative '../json'

class RailsAdmin::Config::Model::Fields::Array::Json < RailsAdmin::Config::Model::Fields::Array
  include RailsAdmin::Config::Model::Fields::Json::Formatter

  def array_separator
    @array_separator ||= '<br>'.html_safe
  end

  def pretty_array
    super.map{ |item| format_json(item) }
  end

  def export_array
    super&.map{ |item| format_json(item) }
  end

  def truncated_array_options
    { escape: false, full: true }
  end
end
