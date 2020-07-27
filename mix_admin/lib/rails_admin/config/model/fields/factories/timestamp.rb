RailsAdmin::Config::Model::Fields.register_factory do |section, property, fields|
  if property.type == :datetime && !property.name.to_s.end_with?('_at', '_date')
    if property.array?
      fields << RailsAdmin::Config::Model::Fields::Array::Timestamp.new(section, property.name, property)
    else
      fields << RailsAdmin::Config::Model::Fields::Timestamp.new(section, property.name, property)
    end
    true
  else
    false
  end
end
