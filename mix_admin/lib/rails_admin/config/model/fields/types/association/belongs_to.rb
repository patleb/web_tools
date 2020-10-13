class RailsAdmin::Config::Model::Fields::Association::BelongsTo < RailsAdmin::Config::Model::Fields::Association
  register_instance_option :formatted_value do
    (o = value) && associated_model.with(object: o).object_label
  end

  register_instance_option :sortable, memoize: true do
    if associated_model.abstract_model.columns.map(&:name).include? associated_model.object_label_method
      associated_model.object_label_method
    else
      { abstract_model.table_name => method_name }
    end
  end

  register_instance_option :searchable, memoize: true do
    if associated_model.abstract_model.columns.map(&:name).include? associated_model.object_label_method
      [associated_model.object_label_method, { klass => method_name }]
    else
      { klass => method_name }
    end
  end

  register_instance_option :visible? do
    unless section.is_a? RailsAdmin::Config::Model::Sections::Nested
      visible_association?
    end
  end

  register_instance_option :eager_load? do
    true
  end

  def selected_id
    object.send(foreign_key)
  end

  def method_name
    nested_options ? "#{name}_attributes".to_sym : property.foreign_key
  end
end
