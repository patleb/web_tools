class ActionController::Delegator
  extend ActiveSupport::DescendantsTracker
  include ActiveSupport::LazyLoadHooks::Autorun

  class << self
    delegate :memoize, to: 'Current.controller'
    delegate :t, to: I18n
  end
  delegate :memoize, to: 'Current.controller'
  delegate :t, to: I18n

  def self.method_missing(name, *args, **options, &block)
    if Current.controller.respond_to? name, true
      Current.controller.__send__(name, *args, **options, &block)
    else
      raise NoMethodError.new("No method '#{name}' for class #{self} or Current.controller", name)
    end
  end

  def self.respond_to_missing?(name, _include_private = false)
    Current.controller.respond_to?(name, true)
  end

  def method_missing(name, *args, **options, &block)
    if @_locals.has_key? name
      self.class.define_method(name) do
        @_locals[name]
      end
      send(name)
    elsif Current.controller.respond_to? name, true
      Current.controller.__send__(name, *args, **options, &block)
    else
      raise NoMethodError.new("No method '#{name}' for #{self.class} or :locals or Current.controller", name)
    end
  end

  def respond_to_missing?(name, _include_private = false)
    @_locals.has_key?(name) || Current.controller.respond_to?(name, true)
  end

  def self.[](*ivars)
    base_class =
      case ivars.first
      when Symbol, String, nil
        self
      else
        ivars.shift
      end

    Class.new(base_class) do
      define_singleton_method :default_ivars do
        super().merge(ivars)
      end
    end
  end

  def self.default_ivars
    Set.new
  end

  def initialize(**locals)
    self.class.default_ivars.each do |name|
      ivar(name, Current.controller.ivar(name))
    end
    @_locals = locals
    after_initialize
  end

  def after_initialize; end
end
