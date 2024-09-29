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

      def format_input(value)
        super&.sub(/^[\d-]+T/, '')
      end
    end
  end
end
