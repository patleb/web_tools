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
  end
end
