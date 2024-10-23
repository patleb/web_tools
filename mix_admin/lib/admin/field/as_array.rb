module Admin
  module Field::AsArray
    extend ActiveSupport::Concern

    prepended do
      register_option :array_separator do
        false
      end

      register_option :array_bullet do
        false
      end

      register_option :export_separator do
        ' '
      end
    end

    def editable?
      !array? && super
    end

    def type_css_class
      array? ? "#{super} array_type" : super
    end

    def parse_input!(params)
      array? ? raise(NotImplementedError) : super
    end

    def parse_search(value)
      array? ? raise(NotImplementedError) : super
    end

    def parse_value(value)
      array? ? raise(NotImplementedError) : super
    end

    def format_value(value)
      return super unless array?
      return pretty_blank unless value.present?
      array = value.map{ |v| super(v).presence || pretty_blank }
      if array_separator
        separator = '&nbsp;'.html_safe
        separator += array_separator unless array_separator == true
        if array_bullet
          value = array.join(separator + array_bullet).html_safe
          value = array_bullet + value if value.present?
        else
          value = array.join(separator).html_safe
        end
        value + '&nbsp;'.html_safe
      else
        array.join(', ').html_safe
      end
    end

    def format_input(value)
      array? ? raise(NotImplementedError) : super
    end

    def format_export(value)
      array? ? value&.map{ |v| super(v) }&.join(export_separator) : super
    end

    def method?
      array? || super
    end
  end
end
