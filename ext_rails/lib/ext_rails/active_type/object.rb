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
    enum(scopes: false, instance_methods: false, with_keyword_access: false, **)
  end

  def self.enum(name, values = nil, default: nil, scopes: true, instance_methods: true, with_keyword_access: true, **options)
    values, options = options, {} unless values
    raise 'only hash enum is supported' unless values.is_a? Hash

    default = _enum_convert_key with_keyword_access, default

    super(name, values, scopes: false, instance_methods: instance_methods, with_keyword_access: with_keyword_access, **options)

    attribute name, default: proc{ default }
    define_method "#{name}_for_database" do
      self.class.send(name.to_s.pluralize)[self[name]]
    end

    return unless scopes
    values.each_key do |key|
      _enum_convert_key with_keyword_access, key
      singleton_class.define_method(key) do
        where(name => key)
      end
      singleton_class.define_method("not_#{key}") do
        where.not(name => key)
      end
    end
  end

  def self._enum_convert_key(with_keyword_access, value)
    if with_keyword_access
      HashWithKeywordAccess.convert_key(value)
    else
      value.is_a?(Symbol) ? value.to_s : value
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
    hash = attributes
    hash.merge! attribute_aliases.except('id_value').transform_values{ |v| hash[v] }
    hash.to_hwka
  end

  def write_virtual_attribute(name, value)
    value = value.to_s if value.is_a? Symbol
    super
  end
end
