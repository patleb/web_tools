# frozen_string_literal: true

module Admin
  module Fields
    class String < Admin::Field
      register_option :sanitized? do
        false
      end

      register_option :truncated? do
        false
      end

      register_option :array_separator do
        '<br>'.html_safe
      end

      register_option :array_bullet do
        '- '.html_safe
      end

      register_option :export_separator do
        "\n"
      end

      def type_css_class
        "#{super}#{' truncated' if truncated?}"
      end

      def format_value(value)
        sanitized ? sanitize(value) : ERB::Util.html_escape(value)
      end

      def format_index(value)
        return super unless (length = truncated)
        length = MixAdmin.config.truncated_length if length == true
        return super unless value.size > length
        string = value[0, length]
        string << if (url = presenter.viewable_url(anchor: "#{name}_field"))
          a_('.link.link-primary', ascii(:ellipsis), href: url)
        else
          ascii(:ellipsis)
        end
        string = string.html_safe if value.html_safe?
        string
      end

      def default_input_attributes
        super.merge! minlength: min_length, maxlength: max_length
      end

      def max_length
        @max_length ||= [property.try(:limit), valid_length[:maximum]].compact.min
      end

      def min_length
        return @min_length if defined? @min_length
        @min_length = valid_length[:minimum]
      end

      def valid_length
        @valid_length ||= klass.validators_on(name).find{ |v| v.kind == :length }.try(&:options) || {}
      end

      def default_help
        text = super || ''
        if valid_length.present? && valid_length[:is].present?
          text += "#{t('admin.form.char_length_of').capitalize} #{valid_length[:is]}."
        else
          max, min = max_length, min_length
          if max
            text += if min.nil? || min == 0
              "#{t('admin.form.char_length_up_to').capitalize} #{max}."
            else
              "#{t('admin.form.char_length_of').capitalize} #{min}-#{max}."
            end
          end
        end
        text
      end
    end
  end
end
