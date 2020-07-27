class RailsAdmin::Config::Model::Fields::Association::HasOne < RailsAdmin::Config::Model::Fields::Association
  register_instance_option :formatted_value do
    (o = value) && associated_model.with(object: o).object_label
  end

  def editable?
    (nested_options || klass.method_defined?("#{name}_id=")) && super
  end

  def selected_id
    value.try :id
  end

  def method_name
    nested_options ? "#{name}_attributes".to_sym : "#{name}_id".to_sym
  end
end
