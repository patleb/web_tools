# frozen_string_literal: true

module Admin
  module Fields
    class Text < String
      register_option :truncated? do
        true
      end

      register_option :input do
        textarea_ name: input_name, class: input_css_class, **input_attributes
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
        attributes
      end
    end
  end
end
