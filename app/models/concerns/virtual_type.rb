# TODO doesn't work with GlobalID

module VirtualType
  extend ActiveSupport::Concern

  included do
    list_context = self
    list_class = Class.new(VirtualType::List) do
      define_method :klass do
        list_context
      end
      alias_method :model, :klass

      def model_name
        klass.name
      end
    end
    const_set(:List, list_class)

    attribute :id
    self.primary_key = :id
  end

  class_methods do
    def encoding
      "UTF-8"
    end

    def find(id)
      object =
        if loaded?
          all.where(id: id).first || item(id)
        else
          item(id) || all.where(id: id).first
        end
      object or raise ::ActiveRecord::RecordNotFound
    end

    def all
      (Current.virtual_types ||= {})[name] ||= begin
        list = self.list.map do |item|
          item = new(item) if item.is_a? Hash
          item.instance_variable_set(:@new_record, false)
          item
        end
        self::List.new(list)
      end
    end

    def list
      raise NotImplementedError
    end

    def item(id)
      nil
    end

    def virtual?
      true
    end

    def loaded?
      (Current.virtual_types ||= {}).has_key? name
    end
  end
end
