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

      register_option :children_names do
        [foreign_key, foreign_type]
      end

      def allowed_field?
        super && associated_model.any?(&:allowed?)
      end

      def associated_model
        @associated_model ||= property.klass.map(&:admin_model)
      end

      def method_name
        "#{name}_global_id".to_sym
      end
    end
  end
end
