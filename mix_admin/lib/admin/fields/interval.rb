module Admin
  module Fields
    class Interval < Admin::Field
      prepend AsArray

      register_option :pretty_format do
        [:years, :compact]
      end

      def editable?
        false
      end

      def method?
        true
      end

      def format_value(value)
        return unless value
        unit, compact = pretty_format
        value = (unit == :iso8601) ? value.iso8601 : value.to_s(unit, compact: compact)
        value.html_safe
      end
    end
  end
end
