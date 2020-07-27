RailsAdmin::Config::Model::Fields.register_factory do |section, property, fields|
  klass = section.klass
  if property.name == klass.inheritance_column&.to_sym
    field = RailsAdmin::Config::Model::Fields::Sti.new(section, property.name, property)
    fields << field
    field.hide unless klass == klass.base_class
    true
  else
    false
  end
end
