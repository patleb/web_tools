module ActionPolicy
  class NotAuthorizedError < ::StandardError; end

  class Base
    include ActiveSupport::LazyLoadHooks::Autorun

    attr_reader :user, :object

    delegate :actions, to: :class

    def self.actions
      @_actions ||= begin
        index = public_instance_methods.index(:actions)
        public_instance_methods.each_with_index.select_map{ |m, i| m if i < index && m.end_with?('?') }
      end
    end

    def initialize(user, object)
      @user = user
      @object = object.is_a?(String) ? object.to_const! : object
    end

    def param_key
      klass.model_name.param_key
    end

    def params
      []
    end

    def scope(relation)
      self.class::Scope.new(user, relation).resolve
    end

    protected

    def record
      object if record?
    end

    def record?
      !klass?
    end

    def klass
      return @klass if defined? @klass
      @klass = klass? ? object : object.class
    end

    def klass?
      object.is_a? Class
    end

    def method_missing(name, ...)
      if name.end_with? '?'
        self.class.send(:define_method, name) do
          false
        end
        send(name)
      else
        super
      end
    end

    def respond_to_missing?(name, _include_private = false)
      name.end_with?('?') || super
    end

    class Scope
      attr_reader :user, :relation

      def initialize(user, relation)
        @user = user
        @relation = relation
      end

      def resolve
        relation.none
      end
    end
  end
end
