MonkeyPatch.add{['activesupport', 'lib/active_support/current_attributes.rb', '99d25fb3fa37e9afc576ceed47ae8ae62824d23ff90aca6e507d528d815e1622']}

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
