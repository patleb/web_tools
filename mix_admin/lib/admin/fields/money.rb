module Admin
  module Fields
    class Money < Integer
      # include MoneyRails::ActionViewExtension

      def parse_search(value)
        value * 100
      end

      def format_value(value)
        humanized_money_with_symbol(value)
      end
    end
  end
end
