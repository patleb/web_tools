# frozen_string_literal: true

module Admin
  module Fields
    class Text < String
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
        attributes.merge! maxlength: max_length
      end
    end
  end
end
