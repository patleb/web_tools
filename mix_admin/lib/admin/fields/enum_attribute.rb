module Admin
  module Fields
    class EnumAttribute < Enum
      def self.has?(section, property)
        klass = section.klass
        klass.respond_to?(:defined_enums) && klass.defined_enums.has_key?(property.name.to_s)
      end

      register_option :pretty_value do
        i18n_value(value)
      end

      register_option :enum do
        values = enum_values
        if values.is_a? Array
          values.map{ |value| [i18n_value(value), value] }
        else
          values.each_with_object([]) do |(key, value), all|
            all << [i18n_value(key), value]
          end
        end
      end

      register_option :multiple? do
        false
      end

      def parse_input!(params)
        value = params[column_name]
        return unless value
        params[column_name] = klass.attribute_types[column_name.to_s].deserialize(value)
      end

      def parse_search(value)
        if value.to_i?
          parse_value(value)
        else
          value = value.slugify
          enum.each_with_object([]) do |(text_value, db_value), values|
            values << db_value if text_value.slugify.include? value
          end
        end
      end

      def parse_value(value)
        return unless value.present?
        klass.attribute_types[name.to_s].serialize(value)
      end

      def format_value(value)
        value = parse_value(value)
        (!value.nil? && enum[value]) || value
      end

      def search_type
        property.column.type
      end

      def i18n_value(key)
        klass.human_attribute_name("#{name}/#{key}", default: key.to_s.humanize)
      end
    end
  end
end
