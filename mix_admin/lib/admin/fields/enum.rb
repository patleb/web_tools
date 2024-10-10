module Admin
  module Fields
    class Enum < Admin::Field
      def self.has?(section, property)
        klass = section.klass
        method_name = "enum_#{property.name}"
        klass.respond_to?(method_name) || klass.method_defined?(method_name)
      end

      register_option :input do
        options = { include_blank: include_blank?, selected: input_value, object: form.object }
        html_options = input_attributes
        html_options[:multiple] = true if multiple?
        form.select(method_name, enum, options, html_options)
      end

      register_option :enum_labels, memoize: :locale do
        nil
      end

      register_option :enum_method, memoize: true do
        method_name = "enum_#{plural_name}"
        if klass.respond_to?(method_name) || model.respond_to?(method_name)
          method_name
        else
          name.to_s.pluralize
        end
      end

      register_option :enum do
        enum_values
      end

      register_option :include_blank? do
        enum.to_a.map(&:last).none?(&:blank?)
      end

      register_option :multiple? do
        property && [:serialized].include?(property.type)
      end

      def enum_values
        if klass.respond_to? enum_method
          klass.public_send(enum_method)
        else
          presenter.public_send(enum_method)
        end
      end

      def parse_value(value)
        return unless value.present?
        case klass.attribute_types[name.to_s]
        when ActiveModel::Type::Integer
          value if value.to_i?
        else
          value
        end
      end

      def format_value(value)
        if (labels = enum_labels)
          if labels.has_key? value
            type, text = labels[value]
            return span_ ".label.label-#{type}", text
          end
        end
        value = value.to_s
        if (list = enum).is_a? Hash
          list.reject{ |_k, v| v.to_s != value }.keys.first.to_s.presence || value
        elsif list.is_a?(::Array) && list.first.is_a?(::Array)
          list.find{ |e| e[1].to_s == value }.try(:first).to_s.presence || value
        else
          value
        end
      end

      def search_type
        :string
      end
    end
  end
end
