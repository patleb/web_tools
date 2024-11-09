module Admin
  module Fields
    class Json < Admin::Field
      def editable?
        false
      end

      def method?
        true
      end

      def parse_input!(params)
        params[column_name] = parse_input(params[column_name]) if params[column_name].is_a? String
      end

      def parse_input(value)
        value.present? ? (ActiveSupport::JSON.decode(value) rescue nil) : nil
      end

      def format_value(value)
        value&.pretty_json(:html)
      end
    end
  end
end
