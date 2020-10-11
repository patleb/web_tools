module RailsAdmin
  module AbstractModel::ActiveRecord
    class Association
      attr_reader :column, :reflection

      delegate :options, :scope, :polymorphic?, to: :reflection
      delegate :polymorphic_parents, to: 'RailsAdmin::AbstractModel'

      delegate_missing_to :column

      def initialize(reflection, klass)
        @reflection = reflection
        @column = klass.columns_hash[reflection.foreign_key.to_s]
        @klass = klass
      end

      def name
        reflection.name.to_sym
      end

      def type
        reflection.macro
      end

      def klass
        if polymorphic?
          polymorphic_parents(@klass, name) || []
        else
          reflection.klass
        end
      end

      def primary_key
        (options[:primary_key] || reflection.klass.primary_key)&.to_sym unless polymorphic?
      end

      def foreign_key
        reflection.foreign_key.to_sym
      end

      def foreign_type
        reflection.foreign_type&.to_sym
      end

      def as
        options[:as]&.to_sym
      end

      def inverse_of
        reflection.send(:inverse_name)&.to_sym
      end

      def nested_options
        @klass.nested_attributes_options.try{ |o| o[name.to_sym] }
      end

      def association?
        true
      end

      def required?(_object = nil)
        return false if foreign_key.nil? || type != :has_many
        column.nil_or_false?(:null)
      end

      def readonly?(_object = nil)
        column && @klass.readonly_attributes.include?(column.name) ||
          !polymorphic? && scope.is_a?(Proc) && klass.all.instance_eval(&scope).readonly_value ||
          reflection.nested?
      end
    end
  end
end
