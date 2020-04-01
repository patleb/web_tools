ActiveSupport::CurrentAttributes.class_eval do
  include ActiveSupport::LazyLoadHooks::Autorun

  def self.[](name)
    attributes[name.to_sym]
  end

  def self.[]=(name, value)
    attribute name unless respond_to? name
    attributes[name.to_sym] = value
  end

  def self.has_attribute?(name)
    attributes.has_key? name
  end
end
