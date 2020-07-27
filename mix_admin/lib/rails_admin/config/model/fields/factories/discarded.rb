RailsAdmin::Config::Model::Fields.register_factory do |section, property, fields|
  if property.name == section.klass.discard_column&.to_sym
    fields << RailsAdmin::Config::Model::Fields::Discarded.new(section, property.name, property)
    true
  else
    false
  end
end
