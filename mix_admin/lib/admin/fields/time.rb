# NOTE ActiveRecord Time attribute is always dirty even when the value is the same.
module Admin
  module Fields
    class Time < DateTime
      register_option :i18n_scope do
        [:time, :formats, :pretty]
      end

      def format_input(value)
        value = value&.utc if utc?
        super&.sub(/^[\d-]+T/, '')
      end

      def input_type
        :time
      end
    end
  end
end
