class RailsAdmin::Config::Model::Fields::Sti < RailsAdmin::Config::Model::Fields::Enum
  register_instance_option :enum do
    klass.self_and_inherited_types.map do |type|
      [RailsAdmin.model(type).label, type.name]
    end
  end

  register_instance_option :pretty_value do
    RailsAdmin.model(value).label
  end

  register_instance_option :multiple? do
    false
  end
end
