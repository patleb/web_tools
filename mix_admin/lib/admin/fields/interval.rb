module Admin
  module Fields
    class Interval < Admin::Field
      register_option :pretty_format do
        :long
      end

      def editable?
        false
      end

      def method?
        true
      end

      def format_value(value)
        case pretty_format
        when :long
          value&.pretty_days
        when :short
          value&.pretty_hours
        when :ceil
          value&.pretty_days(ceil: true)
        when :floor
          value&.pretty_hours(ceil: true)
        else
          value.to_s
        end
      end
    end
  end
end
