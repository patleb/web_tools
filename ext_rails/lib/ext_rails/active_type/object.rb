ActiveType::Object.class_eval do
  class << self
    def virtual_association_names
      virtual_columns_hash.select_map do |name, options|
        next unless options.instance_variable_get(:@type_caster).instance_variable_get(:@type) == :object
        name
      end
    end

    def ar_attribute(name, *args)
      options = args.extract_options!
      type = args.first

      super(name, type, **options.dup)

      type = :array if options.delete(:array)
      attribute(name, type, options)
    end

    def enum(default: nil, **definition)
      raise 'multiple definitions are not supported' if definition.size > 1
      name, values = definition.first
      raise 'only hash enum is supported' unless values.is_a? Hash
      default = default.to_s if default.is_a? Symbol

      super(definition)

      attribute name, default: proc{ default }
      define_method "#{name}_for_database" do
        self.class.send(name.to_s.pluralize)[self[:role]]
      end
      values.each_key do |key|
        key = key.to_s if key.is_a? Symbol
        singleton_class.define_method(key) do
          where(name => key)
        end
      end
    end
  end

  def write_virtual_attribute(name, value)
    value = value.to_s if value.is_a? Symbol
    super
  end
end
