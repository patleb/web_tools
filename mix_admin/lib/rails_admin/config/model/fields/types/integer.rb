class RailsAdmin::Config::Model::Fields::Integer < RailsAdmin::Config::Model::Fields::Base
  require_rel 'integer'

  include self::Formatter

  register_instance_option :pretty_value do
    format_integer
  end

  register_instance_option :export_value do
    formatted_value
  end

  register_instance_option :view_helper do
    :number_field
  end

  register_instance_option :sort_reverse? do
    primary_key?
  end
end
