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
      @object = object
    end

    def param_key
      relation.model_name.param_key
    end

    def params
      []
    end

    def scope(relation)
      self.class::Scope.new(user, relation).resolve
    end

    def index?
      false
    end

    def export?
      false
    end

    def show?
      false
    end

    def new?
      false
    end

    def edit?
      false
    end

    def sort?
      listable? && edit?
    end

    def delete?
      false
    end

    def trash?
      discardable? && delete?
    end

    def restore?
      trash?
    end

    protected

    def discardable?
      relation.discardable?
    end

    def listable?
      relation.listable?
    end

    def record
      object if record?
    end

    def record?
      !relation
    end

    def relation
      return @relation if defined? @relation
      @relation = object.is_a?(Class) ? object : object.class
    end

    def relation?
      !!relation
    end

    def role
      @role ||= user.role.to_sym
    end

    def roles
      @roles ||= user.class.roles.keys
    end

    def method_missing(name, *args, **options, &block)
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
