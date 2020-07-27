module RailsAdmin
  module AbstractModel::ActiveRecord
    class Column
      attr_reader :column, :klass

      delegate_missing_to :column

      def initialize(column, klass)
        @column = column
        @klass = klass
      end

      def name
        column.name.to_sym
      end

      def type
        if klass.type_for_attribute(column.name).class == ::ActiveRecord::Type::Serialized
          :serialized
        else
          column.type
        end
      end

      def length
        column.limit
      end

      def association?
        false
      end

      def required?(object = nil)
        column.true?(:state, object, 'required') || column.nil_or_false?(:null)
      end

      def readonly?(object = nil)
        column.nil_or_true?(:state, object, 'readonly') && klass.readonly_attributes.include?(column.name)
      end

      def visible?(object = nil)
        column.false?(:state, object, 'invisible') || column.nil_or_true?(:visible?)
      end
    end
  end
end
