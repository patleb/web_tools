module Admin
  module Fields
    class EnumAttribute < Enum
      def self.has?(section, property)
        klass = section.klass
        klass.respond_to?(:defined_enums) && klass.defined_enums.has_key?(property.name.to_s)
      end

      register_option :pretty_value do
        klass.human_attribute_name("#{name}.#{value}", default: value.humanize)
      end

      register_option :enum do
        values = enum_values
        if values.is_a? Array
          values.map{ |value| [klass.human_attribute_name("#{name}.#{value}", default: value), value] }
        else
          values.each_with_object([]) do |(key, value), all|
            all << [klass.human_attribute_name("#{name}.#{key}", default: key), value]
          end
        end
      end

      register_option :multiple? do
        false
      end

      def parse_input!(params)
        value = params[name]
        return unless value
        params[name] = klass.attribute_types[name.to_s].deserialize(value)
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
    end
  end
end
