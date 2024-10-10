# frozen_string_literal: true

module Admin
  module Fields
    class String < Admin::Field
      register_option :sanitized? do
        false
      end

      register_option :length do
        property.try(:length)
      end

      register_option :valid_length, memoize: true do
        klass.validators_on(name).find{ |v| v.kind == :length }.try(&:options) || {}
      end

      def format_value(value)
        sanitized ? sanitize(value) : ERB::Util.html_escape(value)
      end

      def default_input_attributes
        super.merge! maxlength: max_length
      end

      def max_length
        @max_length ||= [length, valid_length[:maximum] || nil].compact.min
      end

      def min_length
        @min_length ||= [0, valid_length[:minimum] || nil].compact.max
      end

      def default_help
        text = super || ''
        if valid_length.present? && valid_length[:is].present?
          text += "#{t('admin.form.char_length_of').capitalize} #{valid_length[:is]}."
        else
          max, min = max_length, min_length
          if max
            text += if min == 0
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
