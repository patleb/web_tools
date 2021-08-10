module VirtualRecord
  class Base < ActiveType::Object
    self.primary_key = :id

    ar_attribute :id

    class << self
      delegate :count_estimate, :size, :all?, :empty?, :reverse_order, to: :all

      def scope(name, body)
        raise ArgumentError, "The scope body needs to be callable." unless body.respond_to? :call
        return unless name.match? /^[a-z_][a-z0-9_]*$/
        singleton_class.define_method(name) do |*args|
          body.call(*args)
        end
      end
    end

    def self.inherited(subclass)
      super
      relation_class = Class.new(VirtualRecord::Relation) do
        define_method :klass do
          subclass
        end
        alias_method :model, :klass

        def model_name
          klass.name
        end
      end
      subclass.const_set(:Relation, relation_class)
    end

    def self.ar_connection(type = :main)
      case type
      when :main then ActiveRecord::Main.connection
      when :base then ActiveRecord::Base.connection
      end
    end

    def self.encoding
      "UTF-8"
    end

    def self.find(id)
      object =
        if loaded?
          all.where(id: id).first || item(id)
        else
          item(id) || all.where(id: id).first
        end
      object || raise(ActiveRecord::RecordNotFound)
    end

    def self.all
      (Current.virtual_types ||= {})[name] ||= all!
    end

    def self.all!
      list = self.list.map do |item|
        item = new(item) if item.is_a? Hash
        item.instance_variable_set(:@new_record, false)
        item
      end
      self::Relation.new(list)
    end

    def self.use(relation)
      old_all = all
      Current.virtual_types[name] = relation
      yield
    ensure
      Current.virtual_types[name] = old_all if old_all
    end

    def self.list
      raise NotImplementedError
    end

    def self.item(id)
      nil
    end

    def self.reset
      (Current.virtual_types ||= {})[name] = nil
    end

    def self.loaded?
      (Current.virtual_types ||= {}).has_key? name
    end
  end
end
