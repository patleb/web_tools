# frozen_string_literal: true

ActiveType::Object.class_eval do
  def self.encoding
    "UTF-8"
  end

  def self.nested_attribute_names
    virtual_columns_hash.select_map do |name, options|
      next unless options.type == :object
      name
    end
  end

  def self.enum!(**)
    enum(_scopes: false, _instance_methods: false, **)
  end

  def self.enum(default: nil, _scopes: true, _instance_methods: true, **definition)
    raise 'multiple definitions are not supported' if definition.size > 1
    name, values = definition.first
    raise 'only hash enum is supported' unless values.is_a? Hash
    default = default.to_s if default.is_a? Symbol

    super(name, values, scopes: false, instance_methods: _instance_methods)

    attribute name, default: proc{ default }
    define_method "#{name}_for_database" do
      self.class.send(name.to_s.pluralize)[self[name]]
    end

    return unless _scopes
    values.each_key do |key|
      key = key.to_s if key.is_a? Symbol
      singleton_class.define_method(key) do
        where(name => key)
      end
      singleton_class.define_method("not_#{key}") do
        where.not(name => key)
      end
    end
  end

  def self.scope(name, body)
    raise ArgumentError, "The scope body needs to be callable." unless body.respond_to? :call
    return unless name.match? /^[a-z_][a-z0-9_]*$/
    singleton_class.define_method(name) do |*args|
      body.call(*args)
    end
  end

  def attributes_hash
    attributes.with_indifferent_access
  end

  def write_virtual_attribute(name, value)
    value = value.to_s if value.is_a? Symbol
    super
  end
end
