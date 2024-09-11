module Admin
  module Fields
    class Timestamp < DateTime
      def self.has?(section, property)
        property.type == :datetime && !property.name.end_with?('_at', '_date')
      end

      register_option :i18n_scope do
        [:timestamp, :formats, :pretty]
      end

      def editable?
        false
      end
    end
  end
end
