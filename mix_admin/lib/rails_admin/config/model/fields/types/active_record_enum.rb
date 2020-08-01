class RailsAdmin::Config::Model::Fields::ActiveRecordEnum < RailsAdmin::Config::Model::Fields::Enum
  def type
    :enum
  end

  register_instance_option :enum do
    klass.defined_enums[name.to_s]
  end

  register_instance_option :pretty_value do
    if object.respond_to? "#{enum_method}_i18n"
      object.send("#{enum_method}_i18n")
    else
      object.send(name)
    end
  end

  register_instance_option :multiple? do
    false
  end

  register_instance_option :queryable do
    false
  end

  def parse_value(value)
    return unless value.present?
    klass.attribute_types[name.to_s].serialize(value)
  end

  def parse_input(params)
    value = params[name]
    return unless value
    params[name] = parse_input_value(value)
  end

  def form_value
    value = parse_value(super)
    enum[value] || value
  end

  private

  def parse_input_value(value)
    klass.attribute_types[name.to_s].deserialize(value)
  end
end
