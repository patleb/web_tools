module Admin
  module Fields
    class DateTime < Admin::Field
      register_option :sort_reverse?, memoize: true do
        true
      end

      register_option :view_helper, memoize: true do
        :datetime_field
      end

      register_option :html_attributes do
        __super__(:html_attributes).merge! size: 22
      end

      register_option :strftime_format, memoize: :locale do
        I18n.t(pretty_format, scope: i18n_scope)
      end

      register_option :pretty_format do
        :long
      end

      register_option :i18n_scope do
        [:datetime, :formats, :pretty]
      end

      def parse_input!(params)
        params[name] = parse_value(params[name]) if params[name]
      end

      def parse_value(value)
        return if value.blank?
        return value if %w(DateTime Date Time).include?(value.class.name)
        return if (delocalized_value = delocalize(value)).blank?
        begin
          # Adjust with the correct timezone and daylight saving time
          datetime_with_wrong_tz = ::Time.strptime(delocalized_value, strftime_format.gsub('%-d', '%d'))
          ::Time.parse_utc(datetime_with_wrong_tz.strftime('%Y-%m-%d %H:%M:%S'))
        rescue ArgumentError
          nil
        end
      end

      def format_value(value)
        if value
          I18n.l(value, format: strftime_format)
        else
          ''.html_safe
        end
      end

      def format_export(value)
        value&.iso8601
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

      def search_type
        :datetime
      end

      def delocalize(date_string, format = strftime_format)
        return date_string if Current.locale == :en
        format.to_s.scan(/%[AaBbp]/) do |match|
          case match
          when '%A'
            english = %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
            day_names.each_with_index { |d, i| date_string = date_string.gsub(/#{d}/, english[i]) }
          when '%a'
            english = %w(Sun Mon Tue Wed Thu Fri Sat)
            abbr_day_names.each_with_index { |d, i| date_string = date_string.gsub(/#{d}/, english[i]) }
          when '%B'
            english = %w(January February March April May June July August September October November December)
            month_names.each_with_index { |m, i| date_string = date_string.gsub(/#{m}/, english[i]) }
          when '%b'
            english = %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
            abbr_month_names.each_with_index { |m, i| date_string = date_string.gsub(/#{m}/, english[i]) }
          when '%p'
            date_string = date_string.gsub(/#{I18n.t('date.time.am', default: 'am')}/, 'am')
            date_string = date_string.gsub(/#{I18n.t('date.time.pm', default: 'pm')}/, 'pm')
          end
        end
        date_string
      end

      def abbr_day_names
        (@abbr_day_names ||= {})[Current.locale] ||= begin
          I18n.t('date.abbr_day_names', raise: true)
        rescue I18n::ArgumentError
          %w(Sun Mon Tue Wed Thu Fri Sat)
        end
      end

      def abbr_month_names
        (@abbr_month_names ||= {})[Current.locale] ||= begin
          I18n.t('date.abbr_month_names', raise: true)[1..-1]
        rescue I18n::ArgumentError
          %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
        end
      end

      def date_format
        (@date_format ||= {})[Current.locale] ||= begin
          I18n.t('date.formats.default', raise: true)
        rescue
          '%Y-%m-%d'
        end
      end

      def day_names
        (@day_names ||= {})[Current.locale] ||= begin
          I18n.t('date.day_names', raise: true)
        rescue I18n::ArgumentError
          %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
        end
      end

      def month_names
        (@month_names ||= {})[Current.locale] ||= begin
          I18n.t('date.month_names', raise: true)[1..-1]
        rescue I18n::ArgumentError
          %w(January February March April May June July August September October November December)
        end
      end
    end
  end
end
