module Admin
  module Fields
    class ForeignKey < Integer
      def self.has?(section, property)
        section.model.associations.any? do |association|
          association.type == :belongs_to && association.foreign_key == property.name
        end
      end

      register_option :property_model_name, memoize: true do
        model_name = column_name.to_s.delete_suffix('_id').camelize
        if (namespace = model.model_name.deconstantize).present?
          namespaced_name = "#{namespace}::#{model_name}"
          model_name = namespaced_name if namespaced_name.to_const
        end
        model_name
      end

      def format_value(value)
        "#{property_model.label.upcase_first} ##{value}"
      end

      def format_index(value)
        foreign_key_link(value)
      end

      def foreign_key_link(label)
        url = property_model.viewable_url(id: value)
        url ? a_('.link.text-primary', text: label, href: url) : label
      end

      def property_model
        @property_model ||= property_model_name.to_const.admin_model
      end
    end
  end
end
