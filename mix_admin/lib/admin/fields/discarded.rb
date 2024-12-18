module Admin
  module Fields
    class Discarded < DateTime
      def self.has?(section, property)
        property.name == section.klass.discard_column&.to_sym
      end

      def allowed_field?
        super && action.trashable?
      end

      def editable?
        false
      end
    end
  end
end
