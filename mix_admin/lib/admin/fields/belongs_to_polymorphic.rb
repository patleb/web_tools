module Admin
  module Fields
    class BelongsToPolymorphic < BelongsTo
      def self.has?(section, property)
        return false unless (association = super)
        association.polymorphic?
      end

      register_option :sortable do
        false
      end

      register_option :queryable do
        false
      end

      def allowed_field?
        super && property_model.any?(&:allowed?)
      end

      def property_model
        @property_model ||= property.klass.map(&:admin_model)
      end

      def method_name
        "#{through}_global_id".to_sym
      end

      def association_names
        [foreign_key, foreign_type]
      end
    end
  end
end
