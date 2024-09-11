module Admin
  module Fields
    class Boolean < Admin::Field
      register_option :render do
        value = form_value
        form.send view_helper, method_name, html_attributes.reverse_merge(value: value, checked: value.to_b)
      end

      register_option :view_helper, memoize: true do
        :check_box
      end

      register_option :export_format, memoize: true do
        :boolean_and_null
      end

      def format_value(value)
        case value
        when TrueClass  then span_('.true', ascii(:check))
        when FalseClass then span_('.false', ascii(:cross))
        else                 span_('.nil', ascii(:dash))
        end.html_safe
      end

      def format_export(value)
        case export_format
        when :boolean_and_null then value.nil? ? 'null' : value.to_s
        when :integer_and_null then value.nil? ? 'null' : value.to_i.to_s
        when :integer          then value.nil? ? '' : value.to_i.to_s
        else value.to_s
        end
      end

      def generic_help
        false
      end

      def search_type
        :boolean
      end
    end
  end
end
