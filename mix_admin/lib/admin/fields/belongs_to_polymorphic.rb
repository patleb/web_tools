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
        Admin::Field.__call__(__method__, self) && property_models.any?(&:allowed?)
      end

      def property_model
        property_models.first
      end

      def property_models
        @property_models ||= property.klass.map(&:admin_model).compact
      end

      def method_name
        nested? ? super : "#{through}_global_id".to_sym
      end

      def association_names
        [foreign_key, foreign_type]
      end
    end
  end
end
