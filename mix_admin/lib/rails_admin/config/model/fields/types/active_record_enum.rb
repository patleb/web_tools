class RailsAdmin::Config::Model::Fields::ActiveRecordEnum < RailsAdmin::Config::Model::Fields::Enum
  def type
    :enum
  end

  register_instance_option :enum do
    klass.defined_enums[name.to_s]
  end

  register_instance_option :pretty_value do
    object.send(name)
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
    enum[super] || super
  end

  private

  def parse_input_value(value)
    klass.attribute_types[name.to_s].deserialize(value)
  end
end
