module Admin
  module Fields
    class Password < String
      def self.has?(section, property)
        property.name.to_s.match? /(^|_)password(_|$)/
      end

      def allowed_field?
        super && section.is_a?(Admin::Sections::New)
      end

      def parse_input!(params)
        params.delete(column_name) unless params[column_name].present?
      end

      def format_value(value)
        '*' * (min_length || 12) if value
      end

      def input_value
        nil
      end

      def input_type
        :password
      end
    end
  end
end
