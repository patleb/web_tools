module Admin
  module Fields
    class Decimal < Admin::Field
      def input_type
        :number
      end

      def search_type
        :numeric
      end
    end
  end
end
