class RailsAdmin::Config::Model::Fields::ActiveRecordEnum < RailsAdmin::Config::Model::Fields::Enum
  def type
    :enum
  end

  register_instance_option :enum do
    values = enum_values
    if values.is_a? Array
      values.map{ |value| [klass.human_attribute_name("#{name}.#{value}", default: value), value] }
    else
      values.each_with_object([]) do |(key, value), all|
        all << [klass.human_attribute_name("#{name}.#{key}", default: key), value]
      end
    end
  end

  register_instance_option :pretty_value do
    klass.human_attribute_name("#{name}.#{value}", default: value)
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
