module ActionPolicy
  class Base
    include ActiveSupport::LazyLoadHooks::Autorun

    attr_reader :user, :record

    delegate :actions, to: :class

    def self.actions
      @_actions ||= begin
        index = public_instance_methods.index(:record)
        methods = public_instance_methods.each_with_index.select{ |_, i| i < index }.map(&:first)
        methods.select{ |m| m.to_s.end_with? '?' }
      end
    end

    def self.enum(klass, name, *values)
      list = klass.try("#{name}_i18n") || klass.send(name)
      list = list.slice(*values) if values.any?
      list.invert
    end

    def initialize(user, record)
      @user = user
      @record = record
    end

    def role
      @role ||= user.role.to_sym
    end

    def roles
      @roles ||= user.class.roles.keys
    end

    def method_missing(name, *args, &block)
      if name.to_s.end_with? '?'
        self.class.send(:define_method, name) do
          false
        end
        send(name)
      else
        super
      end
    end

    def respond_to_missing?(name, _include_private = false)
      name.to_s.end_with?('?') || super
    end

    class Scope
      attr_reader :user, :scope

      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve
        scope.all
      end
    end
  end
end
