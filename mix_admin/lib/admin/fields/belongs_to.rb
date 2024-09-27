module Admin
  module Fields
    class BelongsTo < Admin::Field
      prepend Field::AsAssociation

      def self.has?(section, property)
        association = section.model.associations_hash[property.name]
        association&.type == :belongs_to ? association : false
      end

      register_option :sortable, memoize: true do
        if associated_model.columns_hash.has_key? associated_model.record_label_method
          associated_model.record_label_method
        else
          { model.table_name => method_name }
        end
      end

      register_option :queryable, memoize: true do
        if associated_model.columns_hash.has_key? associated_model.record_label_method
          [associated_model.record_label_method, { klass => method_name }]
        else
          { klass => method_name }
        end
      end

      register_option :children_names, memoize: true do
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
