module RailsAdmin
  module Config
    module Proxyable
      attr_accessor :bindings

      delegate :authorized?, :authorized_path_for, to: 'Current.controller'
      delegate :translate, :t, to: :I18n

      def abstract_model
        bindings.try{ |o| o[:abstract_model] }
      end

      def object
        bindings.try{ |o| o[:object] }
      end

      def objects
        bindings.try{ |o| o[:objects] }
      end

      def form
        bindings.try{ |o| o[:form] }
      end

      def with(bindings = {})
        Proxy.new(self, bindings)
      end

      def method_missing(name, *args, &block)
        if Current.view.respond_to? name
          Current.view.public_send(name, *args, &block)
        elsif Current.controller.respond_to? name, true
          Current.controller.__send__(name, *args, &block)
        else
          raise NoMethodError, "No method '#{name}' for #{self.class} or Current.view or Current.controller"
        end
      end

      def respond_to_missing?(name, include_private = false)
        Current.view.respond_to?(name, include_private) || Current.controller.respond_to?(name, true)
      end

      class Proxy < BasicObject
        attr_reader :bindings

        def initialize(object, bindings = {})
          @object = object
          @bindings = bindings
        end

        # Bind variables to be used by the configuration options
        def bind(key, value = nil)
          if key.is_a? ::Hash
            @bindings = key
          else
            @bindings[key] = value
          end
          self
        end

        def method_missing(name, *args, &block)
          old_bindings = @object.instance_variable_get(:@bindings)
          @object.instance_variable_set(:@bindings, @bindings)
          @object.__send__(name, *args, &block)
        ensure
          @object.instance_variable_set(:@bindings, old_bindings)
        end

        def respond_to_missing?(name, _include_private = false)
          @object.respond_to?(name, true)
        end
      end
    end
  end
end
