module Admin
  module Fields
    class Money < Integer
      # include MoneyRails::ActionViewExtension

      register_option :pretty_value do
        humanized_money_with_symbol(value)
      end

      def parse_search(value)
        value * 100
      end
    end
  end
end
