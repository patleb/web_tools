# frozen_string_literal: true

module Admin
  module Fields
    class Password < String
      def self.has?(section, property)
        property.name.to_s.match? /(^|_)password(_|$)/
      end

      register_option :pretty_value do
        '*' * MixUser.config.min_password_length
      end

      def allowed_field?
        super && section.is_a?(Admin::Sections::New)
      end

      def parse_input!(params)
        if params[column_name].present?
          params[column_name] = params[column_name] # NOTE in case the password needs to be cleaned
        else
          params.delete(column_name)
        end
      end

      def format_value(value)
        ''.html_safe
      end

      def value
        ''
      end

      def input_type
        :password
      end
    end
  end
end
