class RailsAdmin::Config::Model::Fields::Array::OdooMany < RailsAdmin::Config::Model::Fields::Array::String
  include RailsAdmin::Config::Model::Fields::OdooOne::Formatter

  register_instance_option :pretty_value do
    pretty_array.size
  end

  register_instance_option :index_value do
    pretty_value
  end

  def pretty_array
    super.map{ |item| pretty_format_one(item) }
  end

  def export_array
    super&.map{ |item| export_format_one(item) }
  end
end
