ActiveType::Object.class_eval do
  class << self
    def ar_attribute(name, *args)
      options = args.extract_options!
      type = args.first
      super(name, type, **options.dup)
      attr_readonly(name)
      type = :array if options.delete(:array)
      attribute(name, type, options)
    end

    def attr_enum(default: nil, **definition)
      enum(definition)
      name, _values = definition.first
      default = default.nil? ? nil : default.to_s
      attribute name, default: proc{ default }
      define_method "#{name}_for_database" do
        self.class.send(name.to_s.pluralize)[default]
      end
    end
  end
end
