# Register a custom field factory for devise model
RailsAdmin::Config::Model::Fields.register_factory do |section, property, fields|
  if property.name == :encrypted_password
    extensions = [:password_salt, :reset_password_token, :remember_token]
    fields << RailsAdmin::Config::Model::Fields.load(:password).new(section, :password, property)
    fields << RailsAdmin::Config::Model::Fields.load(:password).new(section, :password_confirmation, property)
    extensions.each do |ext|
      next unless (column = section.abstract_model.columns.find{ |column| ext == column.name })
      unless (field = fields.find{ |f| f.name == ext })
        RailsAdmin::Config::Model::Fields.default_factory.call(section, column, fields)
        field = fields.last
      end
      field.hide
    end
    true
  else
    false
  end
end
