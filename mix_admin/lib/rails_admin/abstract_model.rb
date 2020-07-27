module RailsAdmin
  class AbstractModel
    cattr_accessor :all
    attr_reader :model_name

    class << self
      def reset
        @@all = nil
      end

      def all
        @@all ||= Config.models_pool.each_with_object({}) do |model_name, all|
          abstract_model = new_if_record_type(model_name)
          all[model_name] = abstract_model if abstract_model
        end
      end

      def find(model)
        all[RailsAdmin.model_name(model)]
      end

      def new_if_record_type(model_name)
        klass = ActiveSupport::Dependencies.constantize(model_name)
        if (klass < ::ActiveRecord::Base && !klass.abstract_class?) \
        || (defined?(Ooor::Base) && klass < Ooor::Base)
          new(model_name)
        end
      end

      def polymorphic_parents(klass, name)
        klass.model_types.polymorphic_parents[klass.name][name]
      end
    end

    def initialize(model_name)
      @model_name = model_name
      initialize_active_record
    end

    # do not store a reference to the klass, does not play well with ActiveSupport::Reloader
    def klass
      ActiveSupport::Dependencies.constantize(@model_name)
    end

    def to_s
      klass.to_s
    end

    def model
      Config.model(@model_name)
    end

    def to_param
      klass.model_name.admin_param
    end

    def param_key
      klass.model_name.admin_param_key
    end

    def pretty_name(options = {})
      klass.model_name.human(options)
    end

    def url_for(action, id: nil, **params)
      action = action.to_s
      if id
        RailsAdmin.url_for(action: action, model_name: to_param, id: '__ID__', **params).sub('__ID__', id.to_s)
      else
        RailsAdmin.url_for(action: action, model_name: to_param, **params)
      end
    end

    def where(conditions)
      klass.where(conditions)
    end

    def map_associated_children(object)
      associations.map do |association|
        case association.type
        when :has_one
          if (child = object.send(association.name))
            yield(association, [child])
          end
        when :has_many
          children = object.send(association.name)
          yield(association, Array.new(children))
        end
      end
    end

    private

    def initialize_active_record
      require 'rails_admin/abstract_model/active_record'
      extend AbstractModel::ActiveRecord
    end

    def parse_field_value(field, value)
      value.is_a?(Array) ? value.map { |v| field.parse_value(v) } : field.parse_value(value)
    end
  end
end
