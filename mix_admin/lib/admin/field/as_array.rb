module Admin
  module Field::AsArray
    extend ActiveSupport::Concern

    prepended do
      register_option :pretty_value do
        array = pretty_array(value)
        if pretty_separator
          if array_bullet
            value = array.join(pretty_separator + array_bullet).html_safe
            value = array_bullet + value if value.present?
            value
          else
            array.join(pretty_separator).html_safe
          end
        else
          array.join(', ').html_safe
        end
      end

      register_option :pretty_separator do
        '<br>'.html_safe
      end

      register_option :array_bullet do
        '- '.html_safe
      end

      register_option :export_value do
        export_array(value)&.join(export_separator)
      end

      register_option :export_separator do
        "\n"
      end
    end

    def pretty_array(value)
      return pretty_blank unless value.present?
      value.map{ |v| format_value(v).presence || pretty_blank }
    end

    def export_array(value)
      value&.map{ |v| format_export(v) }
    end

    def parse_value(value)
      value.map{ |v| super(v) }
    end

    def editable?
      false
    end

    def method?
      true
    end
  end
end
