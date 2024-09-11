module Admin
  module Fields
    class Decimal < Admin::Field
      def search_type
        :numeric
      end
    end
  end
end
