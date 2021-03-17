# TODO https://github.com/github/view_component
module ActionPresenter
  class Base
    def self.[](*ivars)
      base_class =
        case ivars.first
        when Symbol, String, nil
          self
        else
          ivars.shift
        end

      Class.new(base_class) do
        define_singleton_method :_instance_variables do
          super().merge(ivars)
        end
      end
    end

    def self._instance_variables
      Set.new
    end

    def initialize(*ivars, **locals)
      (ivars.presence || self.class._instance_variables).each do |ivar|
        instance_variable_set(ivar, Current.view.instance_variable_get(ivar))
      end

      @_locals = locals

      after_initialize
    end

    def after_initialize; end

    def method_missing(name, *args, **options, &block)
      if @_locals.has_key? name
        @_locals[name]
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
  end
end
