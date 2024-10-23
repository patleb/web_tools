module Admin
  module Fields
    class ForeignKey < Integer
      def self.has?(section, property)
        section.model.associations.any? do |association|
          association.type == :belongs_to && association.foreign_key == property.name
        end
      end

      register_option :pretty_value do
        "#{property_model.label.upcase_first} ##{value}"
      end

      register_option :index_value do
        foreign_key_link
      end

      register_option :property_model_name, memoize: true do
        model_name = column_name.to_s.delete_suffix('_id').camelize
        if (namespace = model.model_name.deconstantize).present?
          namespaced_name = "#{namespace}::#{model_name}"
          model_name = namespaced_name if namespaced_name.to_const
        end
        model_name
      end

      def property_model
        @property_model ||= property_model_name.to_const.admin_model
      end

      # TODO redirect discarded :show/:edit to :trash_index with params[:ids] = id
      def foreign_key_link(label = pretty_value)
        url = property_model.viewable_url(id: value)
        url ? a_('.link.text-primary', text: label, href: url) : label
      end
    end
  end
end
