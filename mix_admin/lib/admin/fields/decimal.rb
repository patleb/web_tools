module Admin
  module Fields
    class Decimal < Admin::Field
      prepend AsArray

      def input_type
        :number
      end

      def default_input_attributes
        super.merge! step: 'any'
      end

      def search_type
        :numeric
      end
    end
  end
end
