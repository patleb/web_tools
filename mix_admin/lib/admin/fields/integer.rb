# frozen_string_literal: true

module Admin
  module Fields
    class Integer < Admin::Field
      register_option :sort_reverse?, memoize: true do
        primary_key?
      end

      register_option :input_type do
        :number
      end

      def format_value(value)
        value&.pretty_int&.gsub(' ', '&nbsp;')&.html_safe
      end

      def search_type
        :numeric
      end
    end
  end
end
