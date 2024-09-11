module Admin
  module Fields
    class String < Admin::Field
      register_option :html_attributes do
        __super__(:html_attributes).merge! maxlength: max_length,size: input_size
      end

      register_option :sanitized?, memoize: true do
        false
      end

      register_option :length, memoize: true do
        property.try(:length)
      end

      register_option :valid_length, memoize: true do
        klass.validators_on(name).find{ |v| v.kind == :length }.try(&:options) || {}
      end

      def format_value(value)
        sanitized ? sanitize(value) : ERB::Util.html_escape(value)
      end

      def input_size
        @input_size ||= [50, length.to_i].reject(&:zero?).min
      end

      def max_length
        @max_length ||= [length, valid_length[:maximum] || nil].compact.min
      end

      def min_length
        @min_length ||= [0, valid_length[:minimum] || nil].compact.max
      end

      def generic_help
        text = super
        if valid_length.present? && valid_length[:is].present?
          text += "#{I18n.t('admin.form.char_length_of').capitalize} #{valid_length[:is]}."
        else
          max, min = max_length, min_length
          if max
            text += if min == 0
              "#{I18n.t('admin.form.char_length_up_to').capitalize} #{max}."
            else
              "#{I18n.t('admin.form.char_length_of').capitalize} #{min}-#{max}."
            end
          end
        end
        text
      end
    end
  end
end
