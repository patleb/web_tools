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

      register_option :pretty? do
        true
      end

      def format_value(value)
        if value.is_a? Range
          value = [value.begin, value.end]
          value = value.map(&:pretty_int) if pretty?
          value.join('...').html_safe
        else
          return value unless pretty?
          value.pretty_int.html_safe if value
        end
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
