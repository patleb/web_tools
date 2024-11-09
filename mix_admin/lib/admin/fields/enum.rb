module Admin
  module Fields
    class Enum < Admin::Field
      def self.has?(section, property)
        klass = section.klass
        klass.respond_to?(:defined_enums) && klass.defined_enums.has_key?(property.name.to_s)
      end

      register_option :input do
        value = input_value
        options = include_blank ? [option_(' ', value: '', selected: value.blank?)] : []
        options += _enum.map do |label, option|
          option_(label, value: option, selected: option == value)
        end
        select_ options, name: input_name, class: input_css_class, **input_attributes
      end

      register_option :enum do
        klass.defined_enums[column_name.to_s]
      end

      register_option :include_blank? do
        !required?
      end

      def parse_input!(params)
        return unless (value = params[column_name])
        params[column_name] = klass.attribute_types[column_name.to_s].deserialize(value)
      end

      def parse_search(value)
        labels = _enum
        end_with = value.start_with?('%') && !!(value = value.delete_prefix('%'))
        start_with = value.end_with?('%') && !!(value = value.delete_suffix('%'))
        value = if value.blank?
          []
        elsif start_with && end_with
          labels.select_map{ |label, db_value| db_value if label.simplify.include? value }
        elsif start_with
          labels.select_map{ |label, db_value| db_value if label.simplify.start_with? value }
        elsif end_with
          labels.select_map{ |label, db_value| db_value if label.simplify.end_with? value }
        else
          labels.select_map{ |label, db_value| db_value if label.simplify == value }
        end
        value.empty? ? :_skip : value
      end

      def format_value(value)
        i18n_value(value)
      end

      def input_value
        klass.attribute_types[column_name.to_s].serialize(value)
      end

      def search_operator(operator, value)
        operator.sub('NOT ', '!').sub('ILIKE', '=')
      end

      def _enum
        (@_enum ||= {})[Current.locale] ||= begin
          values = enum
          if values.is_a? Array
            values.map{ |value| [i18n_value(value), value] }
          else
            values.each_with_object([]) do |(key, value), all|
              all << [i18n_value(key), value]
            end
          end
        end
      end

      private

      def i18n_value(key)
        key.present? ? klass.human_attribute_name("#{name}/#{key}", default: key.to_s.humanize) : key
      end
    end
  end
end
