module Admin
  module Fields
    class Bytes < Admin::Field
      def self.has?(section, property)
        property.type == :integer && property.name.end_with?('_bytes')
      end

      def format_value(value)
        number_to_human_size(value)
      end

      def input_type
        :number
      end

      def search_type
        :numeric
      end
    end
  end
end
