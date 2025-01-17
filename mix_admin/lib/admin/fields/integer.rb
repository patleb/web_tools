module Admin
  module Fields
    class Integer < Admin::Field
      register_option :sort_reverse? do
        primary_key?
      end

      register_option :array_separator do
        false
      end

      register_option :array_bullet do
        false
      end

      def format_value(value)
        value = [value.begin, value.end] if value.is_a? Range
        value.pretty_int.html_safe if value
      end

      def input_type
        :number
      end

      def search_type
        :numeric
      end
    end
  end
end
