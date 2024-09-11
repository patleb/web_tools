module Admin
  module Fields
    class Uuid < String
      def self.has?(section, property)
        property.name.to_s.match? /(^|_)uuid(_|$)/
      end

      def editable?
        false
      end

      def search_type
        :uuid
      end
    end
  end
end
