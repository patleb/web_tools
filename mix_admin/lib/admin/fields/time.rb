# frozen_string_literal: true

module Admin
  module Fields
    class Time < DateTime
      register_option :input_type do
        :time
      end

      register_option :i18n_scope do
        [:time, :formats, :pretty]
      end

      def parse_value(value)
        super&.change(year: 2000, month: 1, day: 1)
      end

      def format_input(value)
        super&.sub(/^[\d-]+T/, '')
      end
    end
  end
end
