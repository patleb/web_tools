class RailsAdmin::Config::Model::Fields::Serialized < RailsAdmin::Config::Model::Fields::Text
  register_instance_option :formatted_value do
    self.class.yaml_dump(value) unless value.nil?
  end

  register_instance_option :readonly?, memoize: true do
    true
  end

  def virtual?
    true
  end

  def parse_value(value)
    value.present? ? (self.class.yaml_load(value) || nil) : nil
  end

  def parse_input(params)
    params[name] = parse_value(params[name]) if params[name].is_a? String
  end

  # Backwards-compatible with safe_yaml/load when SafeYAML isn't available.
  # Evaluates available YAML loaders at boot and creates appropriate method,
  # so no conditionals are required at runtime.
  def self.yaml_load(yaml)
    YAML.safe_load(yaml)
  end

  def self.yaml_dump(object)
    YAML.dump(object)
  end
end
