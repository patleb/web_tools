# frozen_string_literal: true

module Admin
  module Fields
    class DateTime < Admin::Field
      register_option :sort_reverse? do
        true
      end

      register_option :strftime_format, memoize: :locale do
        t(pretty_format, scope: i18n_scope)
      end

      register_option :pretty_format do
        :long
      end

      register_option :i18n_scope do
        [:datetime, :formats, :pretty]
      end

      def parse_input!(params)
        params[column_name] = parse_input(params[column_name]) if params[column_name]
      end

      def parse_input(value)
        ::Time.zone.parse(value) if value.present?
      end

      def format_value(value)
        if value
          I18n.l(value, format: strftime_format)
        else
          ''.html_safe
        end
      end

      def format_export(value)
        value&.utc&.iso8601
      end

      def format_input(value)
        value&.iso8601&.sub(/(Z|[-+]\d{2}:\d{2})$/, '')
      end

      def value
        value_in_timezone(super)
      end

      def value_in_timezone(value)
        case value
        when Time, Date, DateTime
          value.in_time_zone
        else
          value
        end
      end

      def input_type
        'datetime-local'
      end

      def default_input_attributes
        super.merge! size: 22
      end

      def search_type
        :datetime
      end
    end
  end
end
