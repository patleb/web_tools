# TODO doesn't work with GlobalID
module VirtualRecord
  class Base < ActiveType::Object
    self.primary_key = :id

    ar_attribute :id

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
      object || raise(::ActiveRecord::RecordNotFound)
    end

    def self.all
      (Current.virtual_types ||= {})[name] ||= begin
        list = self.list.map do |item|
          item = new(item) if item.is_a? Hash
          item.instance_variable_set(:@new_record, false)
          item
        end
        self::Relation.new(list)
      end
    end

    def self.list
      raise NotImplementedError
    end

    def self.item(id)
      nil
    end

    def self.virtual?
      true
    end

    def self.loaded?
      (Current.virtual_types ||= {}).has_key? name
    end
  end
end
