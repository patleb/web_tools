module RailsAdmin
  module Config
    # A module for all configurables.

    module Configurable
      def self.included(base)
        base.send :extend, ClassMethods
        base.send :include, Proxyable
        base.send :include, Inspectable
      end

      def has_option?(name) # rubocop:disable PredicateName
        self.class.instance_variable_get(:@config_options)&.include? name
      end

      # Register an instance option for this object only
      def register_instance_option(option_name, **options, &default)
        scope = class << self; self; end
        self.class.register_instance_option(option_name, scope, **options, &default)
      end

      def register_deprecated_instance_option(option_name, replacement_option_name = nil, &custom_error)
        scope = class << self; self; end
        self.class.register_deprecated_instance_option(option_name, replacement_option_name, scope, &custom_error)
      end

      private

      def with_recurring(option_name, value_proc, default_proc)
        # Track recursive invocation with an instance variable. This prevents run-away recursion
        # and allows configurations such as
        # label { "#{label}".upcase }
        # This will use the default definition when called recursively.
        if instance_variable_get("@#{option_name}_recurring")
          instance_eval(&default_proc)
        else
          instance_variable_set("@#{option_name}_recurring", true)
          instance_eval(&value_proc)
        end
      ensure
        instance_variable_set("@#{option_name}_recurring", false)
      end

      module ClassMethods
        # Register an instance option. Instance option is a configuration
        # option that stores its value within an instance variable and is
        # accessed by an instance method. Both go by the name of the option.
        def register_instance_option(option_name, scope = self, memoize: nil, &default)
          option_name = option_name.to_s
          options = scope.instance_variable_get(:@config_options) || scope.instance_variable_set(:@config_options, Set.new)
          options << option_name

          # Getter alias
          if option_name.end_with?('?')
            scope.send(:define_method, "#{option_name.chop!}?") do
              send(option_name)
            end
          end

          scope.send(:define_method, option_name) do |default_value = nil, memoized: memoize, &block|
            if !default_value.nil? || block
              # Setter
              instance_variable_set("@#{option_name}_registered", default_value.nil? ? block : default_value)
            else
              # Getter
              value = instance_variable_get("@#{option_name}_registered")
              if value.nil? || value.is_a?(Proc)
                if memoized
                  @option_memoized ||= {}
                  key =
                    case memoized
                    when true
                      option_name
                    when :locale
                      "#{Current.locale}_#{option_name}"
                    when String, Symbol
                      "#{send(memoized)}_#{option_name}"
                    else
                      raise("The #{option_name} :memoized key must be specified as true, :locale or a method name.")
                    end
                  return @option_memoized[key] if @option_memoized.has_key? key
                end
                case value
                when Proc
                  value = with_recurring(option_name, value, default)
                when nil
                  value = instance_eval(&default)
                end
                @option_memoized[key] = value if memoized
              end
              value
            end
          end
        end

        def register_deprecated_instance_option(option_name, replacement_option_name = nil, scope = self)
          scope.send(:define_method, option_name) do |*args, &block|
            if replacement_option_name
              ActiveSupport::Deprecation.warn("The #{option_name} configuration option is deprecated, please use #{replacement_option_name}.")
              send(replacement_option_name, *args, &block)
            elsif block_given?
              yield
            else
              raise("The #{option_name} configuration option is removed without replacement.")
            end
          end
        end

        # Register a class option. Class option is a configuration
        # option that stores it's value within a class object's instance variable
        # and is accessed by a class method. Both go by the name of the option.
        def register_class_option(option_name, **options, &default)
          scope = class << self; self; end
          register_instance_option(option_name, scope, **options, &default)
        end
      end
    end
  end
end
