class RailsAdmin::Config::Model::Fields::OdooOne < RailsAdmin::Config::Model::Fields::String
  require_rel 'odoo_one'

  include self::Formatter

  register_instance_option :pretty_value do
    pretty_format_one
  end

  register_instance_option :formatted_value do
    export_format_one
  end

  register_instance_option :separated?, memoize: true do
    true
  end

  register_instance_option :view_helper do
    :number_field
  end
end
