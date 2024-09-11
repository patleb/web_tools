module Admin
  module Fields
    class Json < Admin::Field
      register_option :readonly?, memoize: true do
        true
      end

      def method?
        true
      end

      def parse_value(value)
        value.present? ? (ActiveSupport::JSON.decode(value) rescue nil) : nil
      end

      def parse_input!(params)
        params[name] = parse_value(params[name]) if params[name].is_a? String
      end

      def format_value(value)
        value&.pretty_json(:html)
      end
    end
  end
end
