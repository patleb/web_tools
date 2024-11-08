module Admin
  module Fields
    class EnumSti < Enum
      def self.has?(section, property)
        property.name == section.klass.inheritance_column&.to_sym
      end

      register_option :enum do # TODO filter/sort/search doesn't work
        klass.self_and_inherited_types.map do |type|
          model = type.admin_model
          [model.label || type.name, type.name]
        end
      end

      def allowed_field?
        super && klass.base_class?
      end

      def editable?
        false
      end

      def format_value(value)
        model = value.to_const.admin_model
        model.label || value
      end
    end
  end
end
