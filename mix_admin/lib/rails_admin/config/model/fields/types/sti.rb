class RailsAdmin::Config::Model::Fields::Sti < RailsAdmin::Config::Model::Fields::Enum
  register_instance_option :enum do
    klass.self_and_inherited_types.map do |type|
      model = RailsAdmin.model(type)
      [model.abstract_model && model.label || type.name, type.name]
    end
  end

  register_instance_option :pretty_value do
    model = RailsAdmin.model(value)
    model.abstract_model && model.label || value
  end

  register_instance_option :multiple? do
    false
  end
end
