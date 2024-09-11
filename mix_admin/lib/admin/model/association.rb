module Admin
  class Model::Association < Model::Column
    attr_reader :reflection

    delegate :options, :scope, :polymorphic?, :list_parent?, to: :reflection

    def initialize(reflection, klass)
      @reflection = reflection
      super(klass.columns_hash[reflection.foreign_key.to_s], klass, reflection.name)
    end

    def required?
      return false if foreign_key.nil? || type != :has_many
      super
    end

    def readonly?
      return true if @column && super
      return true if !polymorphic? && scope.is_a?(Proc) && klass.all.instance_eval(&scope).readonly_value
      @reflection.nested?
    end

    def type
      @reflection.macro
    end

    def virtual?
      false
    end

    def association?
      true
    end

    def klass
      if polymorphic?
        Admin::Model::polymorphic_parents(@klass, @name)
      else
        @reflection.klass
      end
    end

    def primary_key
      if polymorphic?
        :to_global_id
      else
        (options[:primary_key] || @reflection.klass.primary_key)&.to_sym
      end
    end

    def foreign_key
      @reflection.foreign_key.to_sym
    end

    def foreign_type
      @reflection.foreign_type&.to_sym
    end

    def as
      options[:as]&.to_sym
    end

    def inverse_of
      @reflection.send(:inverse_name)&.to_sym
    end

    def nested_options
      @klass.nested_attributes_options.try{ |o| o[@name] }
    end
  end
end
