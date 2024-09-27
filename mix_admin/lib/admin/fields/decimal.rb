module Admin
  module Fields
    class Decimal < Admin::Field
      register_option :input_type do
        :number
      end

      def search_type
        :numeric
      end
    end
  end
end
