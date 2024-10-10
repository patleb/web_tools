# frozen_string_literal: true

module Admin
  module Fields
    class Boolean < Admin::Field
      register_option :export_format do
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

      def input_type
        :checkbox
      end

      def input_css_class
        super
          .switch!('input', 'checkbox')
          .switch!('input-error', 'checkbox-error')
          .switch!('input-bordered', 'checkbox-primary')
      end

      def default_input_attributes
        super.merge! checked: input_value.to_b
      end

      def search_type
        :boolean
      end
    end
  end
end
