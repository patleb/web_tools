module Admin
  module Fields
    class BelongsTo < Admin::Field
      prepend Field::AsAssociation

      def self.has?(section, property)
        association = section.model.associations_hash[property.name]
        association&.type == :belongs_to ? association : false
      end

      register_option :children_names do
        [foreign_key]
      end

      def method_name
        nested_options ? "#{name}_attributes".to_sym : foreign_key
      end

      def search_type
        :numeric
      end

      def associated_id
        presenter[foreign_key]
      end
    end
  end
end
