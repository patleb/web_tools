# frozen_string_literal: true

module Admin
  module Fields
    class Time < DateTime
      register_option :i18n_scope do
        [:time, :formats, :pretty]
      end

      def format_input(value)
        super&.sub(/^[\d-]+T/, '')
      end

      def input_type
        :time
      end
    end
  end
end
