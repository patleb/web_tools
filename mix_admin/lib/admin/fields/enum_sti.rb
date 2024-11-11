module Admin
  module Fields
    class EnumSti < Enum
      def self.has?(section, property)
        super && property.name == section.klass.inheritance_column&.to_sym
      end

      def allowed_field?
        super && klass.base_class?
      end

      def editable?
        false
      end

      private

      def i18n_value(key)
        key.present? ? key.to_const.admin_label : key
      end
    end
  end
end
