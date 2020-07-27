RailsAdmin::Config::Model::Fields.register_factory do |section, property, fields|
  if defined?(::ActiveStorage) \
  && property.try(:association?) \
  && (match = /\A(.+)_attachments?\Z/.match property.name) \
  && %w(Local::ActiveStorage::Attachment ActiveStorage::Attachment).include?(property.klass.to_s)
    name = match[1]
    field = RailsAdmin::Config::Model::Fields.load(property.type == :has_many ? :multiple_active_storage : :active_storage).new(section, name, property)
    fields << field
    associations =
      if property.type == :has_many
        ["#{name}_attachments".to_sym, "#{name}_blobs".to_sym]
      else
        ["#{name}_attachment".to_sym, "#{name}_blob".to_sym]
      end
    children_fields = associations.map do |child_name|
      next unless (child_association = section.abstract_model.associations.find{ |a| a.name.to_sym == child_name })
      child_field = fields.find{ |f| f.name == child_name } || RailsAdmin::Config::Model::Fields.default_factory.call(section, child_association, fields)
      child_field.hide unless field == child_field
      child_field.filterable(false) unless field == child_field
      child_field.name
    end.flatten.compact
    field.children_fields(children_fields)
    true
  else
    false
  end
end
