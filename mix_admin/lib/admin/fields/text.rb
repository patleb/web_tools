module Admin
  module Fields
    class Text < String
      register_option :view_helper, memoize: true do
        :text_area
      end

      register_option :html_attributes do
        __super__(:html_attributes).merge!(
          maxlength: max_length,
          cols: 52,
          rows: [max_length && (max_length / 52.0).ceil, 3].compact.max,
        )
      end

      # TODO
      # def format_value(value)
      #   simple_format(value) if value.present?
      # end
    end
  end
end
