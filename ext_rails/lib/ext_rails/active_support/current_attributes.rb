MonkeyPatch.add{['activesupport', 'lib/active_support/current_attributes.rb', '9f43efe93c4dece2ba003835d14eb521c41ace64d236eb52283b5f8ab5906852']}

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
