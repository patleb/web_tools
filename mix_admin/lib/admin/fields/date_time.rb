module Admin
  module Fields
    class DateTime < Admin::Field
      register_option :sort_reverse? do
        true
      end

      register_option :utc? do
        false
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
        return unless value.present?
        utc ? ::Time.use_zone('UTC'){ ::Time.zone.parse(value) } : ::Time.zone.parse(value)
      end

      def format_value(value)
        case value
        when Range
          value = [value.begin, value.end]
          format = strftime_format
          value = value.map{ |v| I18n.l(v, format: format) }
          format_array(value)
        when ::Time, ::Date, ::DateTime
          I18n.l(value, format: strftime_format)
        when nil
          ''.html_safe
        else
          value
        end
      end

      def format_export(value)
        value&.utc&.iso8601
      end

      def format_input(value)
        value = value&.utc if utc?
        value&.iso8601&.sub(/(Z|[-+]\d{2}:\d{2})$/, '')
      end

      def value
        utc ? ::Time.use_zone('UTC'){ value_in_timezone(super) } : value_in_timezone(super)
      end

      def value_in_timezone(value)
        case value
        when ::Time, ::Date, ::DateTime
          value.in_time_zone
        else
          value
        end
      end

      def input_type
        'datetime-local'
      end

      def default_input_attributes
        super.merge! size: 22, step: 'any'
      end

      def search_type
        :datetime
      end
    end
  end
end
