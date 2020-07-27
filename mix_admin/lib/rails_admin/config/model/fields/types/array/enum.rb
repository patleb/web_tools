require_relative '../enum'

class RailsAdmin::Config::Model::Fields::Array::Enum < RailsAdmin::Config::Model::Fields::Array::String
  include RailsAdmin::Config::Model::Fields::Enum::Formatter

  def pretty_array
    super.map{ |item| pretty_format_enum(item) }
  end

  register_instance_option :multiple? do
    true
  end
end
