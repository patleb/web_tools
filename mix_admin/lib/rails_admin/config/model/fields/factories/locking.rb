RailsAdmin::Config::Model::Fields.register_factory do |section, property, fields|
  if property.name == :lock_version
    field = RailsAdmin::Config::Model::Fields::Hidden.new(section, property.name, property)
    fields << field
    field.hide{ !main_action.edit? }
    true
  else
    false
  end
end
