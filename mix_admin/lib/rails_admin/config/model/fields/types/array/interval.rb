require_relative '../interval'

class RailsAdmin::Config::Model::Fields::Array::Interval < RailsAdmin::Config::Model::Fields::Array
  include RailsAdmin::Config::Model::Fields::Interval::Formatter

  def array_separator
    @array_separator ||= '<br>'.html_safe
  end

  def pretty_array
    super.map{ |item| format_interval(item) }
  end

  def truncated_array_options
    { escape: false, max_items: 1 }
  end
end
