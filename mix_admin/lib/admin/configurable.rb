module Admin
  module Configurable
    extend ActiveSupport::Concern

    module Values
      def values_ref
        @values.transform_values{ [self, nil] }
      end

      def value_parent(name)
        parent_for(name) || super_for(name)
      end

      def value?(name)
        @values.has_key? name
      end
    end

    module Super
      def super_for(name)
        @super if @super&.value?(name)
      end

      def super!(name)
        @super.with(bindings).public_send(name)
      end
    end

    module Parent
      def parent_for(name)
        parent if parent&.value?(name)
      end

      def parent!(name)
        parent.with(bindings).public_send(name)
      end

      def parent
        nil
      end
    end

    class_methods do
      def deprecate_class_option(*args)
        deprecate_option(*args, self.singleton_class)
      end

      def deprecate_option(name, replacement_name, context = self)
        context.define_method name do |*args, **options, &block|
          ActiveSupport::Deprecation.warn("The :#{name} configuration option is deprecated, please use :#{replacement_name}.")
          send(replacement_name, *args, **options, &block)
        end
      end

      def register_class_option(name, instance_reader: false, **options, &default_block)
        if instance_reader
          delegate name, to: :class
          delegate name.chop, to: :class if name.end_with? '?'
        end
        register_option(name, self.singleton_class, **options, &default_block)
      end

      def register_option(name, context = self, memoize: nil, &default_block)
        name = name.to_s
        default_memoize = memoize

        ([context] + (context.singleton_class? ? descendants.map(&:singleton_class) : descendants)).each do |klass|
          klass.ivar(:@options) << name
        end

        if name.end_with? '?'
          context.define_method "#{name.chop!}?" do
            !!public_send(name)
          end
        end

        context.define_method name do |default_value = nil, memoize: nil, &block|
          if !(dynamic = default_value.nil?) || block
            value = dynamic ? block : default_value
            memoized = memoize.nil? ? default_memoize : memoize
            @values[name] = [value, memoized]
          else
            value, memoized = @values[name]
            if memoize.nil?
              memoized = default_memoize if memoized.nil?
            else
              memoized = memoize
            end
            case value
            when nil, Proc, Admin::Configurable, Class
              if memoized
                values = @memoized[name] ||= {}
                key = case memoized
                  when true           then memoized
                  when :locale        then Current.locale
                  when :locale_role   then [Current.locale, Current.user.as_role]
                  when :role          then Current.user.as_role
                  when String, Symbol then public_send(memoized)
                  else raise("The #{name} :memoized key is invalid.")
                  end
                return values[key] if values.has_key? key
              end
              case value
              when nil
                value = instance_eval(&default_block)
              when Proc
                value = with_recurring(name, value, default_block)
              when Admin::Configurable, Class
                value = value.with(bindings).public_send(name)
              end
              values[key] = value if memoized
            end
            value
          end
        end

        unless context.method_defined? :with_recurring
          context.define_method :with_recurring do |name, value_proc, default_proc|
            recurring = (Thread.current[:admin_recurring] ||= {})[self] ||= {}
            if recurring[name]
              parent = self
              while (parent = parent.value_parent(name))
                return parent.with(bindings).public_send(name)
              end
              instance_eval(&default_proc)
            else
              recurring[name] = true
              instance_eval(&value_proc)
            end
          ensure
            Thread.current[:admin_recurring].delete(self)
          end
        end
      end

      def inherited(subclass)
        super
        subclass.singleton_class.ivar(:@options, singleton_class.ivar(:@options).dup)
        subclass.singleton_class.ivar(:@values, singleton_class.values_ref)
        subclass.singleton_class.ivar(:@memoized, {})
        subclass.ivar(:@options, @options.dup)
        subclass.ivar(:@values, values_ref)
        subclass.ivar(:@memoized, {})
      end
    end

    included do
      class << self
        extend Values, Super, Parent

        @options = Set.new
        @values = {}
        @memoized = {}

        def with(*)
          self
        end

        def bindings
          nil
        end
      end

      extend Values, Super, Parent
      include Values, Super, Parent

      @options = Set.new
      @values = {}
      @memoized = {}
    end

    def initialize(...)
      @values = {}
      @memoized = {}
      super
    end

    def with(bindings)
      return self if bindings.empty? || bindings == self.bindings
      object = clone # TODO referenced ivars aren't copied --> is it problematic?
      object.bindings = bindings
      object
    end

    def bindings
      @_bindings ||= {}
    end

    def bindings=(bindings)
      @_bindings = bindings
      @_locals_was ||= {}
      @_locals_was.merge! @_locals
      @_locals = @_locals.merge(bindings)
    end
  end
end
