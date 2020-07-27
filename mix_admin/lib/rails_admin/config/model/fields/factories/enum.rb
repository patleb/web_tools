RailsAdmin::Config::Model::Fields.register_factory do |section, property, fields|
  klass = section.klass
  method_name = "enum_#{property.name}"

  if klass.respond_to?(method_name) || klass.method_defined?(method_name)
    if property.array?
      fields << RailsAdmin::Config::Model::Fields::Array::Enum.new(section, property.name, property)
    else
      fields << RailsAdmin::Config::Model::Fields::Enum.new(section, property.name, property)
    end
    true
  elsif klass.respond_to?(:defined_enums) && klass.defined_enums[property.name.to_s]
    fields << RailsAdmin::Config::Model::Fields::ActiveRecordEnum.new(section, property.name, property)
    true
  else
    false
  end
end
