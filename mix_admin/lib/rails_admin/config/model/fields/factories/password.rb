# Register a custom field factory for property named as password. More property
# names can be registered in RailsAdmin::Config::Model::Fields::Password.column_names
# array.
#
# @see RailsAdmin::Config::Model::Fields::Password.column_names
# @see RailsAdmin::Config::Model::Fields.register_factory
RailsAdmin::Config::Model::Fields.register_factory do |section, property, fields|
  if [:password].include?(property.name)
    fields << RailsAdmin::Config::Model::Fields::Password.new(section, property.name, property)
    true
  else
    false
  end
end
