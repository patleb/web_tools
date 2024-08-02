require 'ext_rails/action_controller/delegator'

class ActionView::Delegator < ActionController::Delegator
  def self.method_missing(name, *args, **options, &block)
    if Current.view.respond_to? name
      Current.view.public_send(name, *args, **options, &block)
    elsif Current.controller.respond_to? name, true
      Current.controller.__send__(name, *args, **options, &block)
    else
      raise NoMethodError.new("No method '#{name}' for class #{self} or Current.view or Current.controller", name)
    end
  end

  def self.respond_to_missing?(name, include_private = false)
    Current.view.respond_to?(name, include_private) || super
  end

  def method_missing(name, *args, **options, &block)
    if @_locals.has_key? name
      self.class.define_method(name) do
        @_locals[name]
      end
      send(name)
    elsif Current.view.respond_to? name
      Current.view.public_send(name, *args, **options, &block)
    elsif Current.controller.respond_to? name, true
      Current.controller.__send__(name, *args, **options, &block)
    else
      raise NoMethodError.new("No method '#{name}' for #{self.class} or :locals or Current.view or Current.controller", name)
    end
  end

  def respond_to_missing?(name, include_private = false)
    @_locals.has_key?(name) || Current.view.respond_to?(name, include_private) || Current.controller.respond_to?(name, true)
  end

  def initialize(**locals)
    self.class.default_ivars.each do |name|
      ivar(name, Current.view.ivar(name))
    end
    @_locals = locals
    after_initialize
  end
end
