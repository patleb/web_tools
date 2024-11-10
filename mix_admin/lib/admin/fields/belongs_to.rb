module Admin
  module Fields
    class BelongsTo < Association
      def self.has?(section, property)
        association = section.model.associations_hash[property.name]
        association&.type == :belongs_to ? association : false
      end

      def method_name
        nested? ? "#{through}_attributes".to_sym : foreign_key
      end

      def association_names
        [foreign_key]
      end

      def search_type
        :numeric
      end
    end
  end
end
