module ActiveType
  module VirtualAttributes
    VirtualColumn.class_eval do
      def type
        @type_caster.type
      end

      def klass
        case type
        when :integer                     then Integer
        when :float                       then Float
        when :decimal                     then BigDecimal
        when :datetime, :timestamp, :time then Time
        when :date                        then Date
        when :text, :string, :binary      then String
        when :boolean                     then Object
        end
      end
    end
  end
end
