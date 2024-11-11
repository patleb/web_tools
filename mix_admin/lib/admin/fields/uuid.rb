module Admin
  module Fields
    class Uuid < Admin::Field
      def self.has?(section, property)
        property.name.to_s.match? /(^|_)uuid(_|$)/
      end

      register_option :array_separator do
        '<br>'.html_safe
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
