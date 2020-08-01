require_relative '../integer'

class RailsAdmin::Config::Model::Fields::Array::Integer < RailsAdmin::Config::Model::Fields::Array
  include RailsAdmin::Config::Model::Fields::Integer::Formatter

  def pretty_array
    if (list = super).is_a? Range
      list = [list.begin, list.end]
    end
    list&.map{ |item| format_integer(item) }
  end

  def truncated_value_options
    super.merge!(escape: false)
  end
end
