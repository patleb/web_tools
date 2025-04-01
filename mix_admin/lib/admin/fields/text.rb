module Admin
  module Fields
    class Text < String
      register_option :truncated? do
        true
      end

      def format_value(value)
        if (truncate_length = truncated).to_i?
          super(truncate(value, length: truncate_length))
        else
          super
        end
      end

      def input_control(**attributes)
        textarea_ **input_attributes, **attributes
      end

      def input_css_class
        super
          .switch!('input', 'textarea')
          .switch!('input-error', 'textarea-error')
          .switch!('input-bordered', 'textarea-bordered')
      end

      def default_input_attributes
        attributes = super
        attributes[:text] = attributes.delete(:value)
        attributes.merge! rows: 10
      end
    end
  end
end
