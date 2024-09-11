module Admin
  module Fields
    class HasOne < Admin::Field
      prepend Field::AsAssociation

      def editable?
        (nested_options || klass.method_defined?("#{name}_id=")) && super
      end

      def method_name
        nested_options ? "#{name}_attributes".to_sym : "#{name}_id".to_sym
      end

      def associated_id
        value.try(property.primary_key)
      end
    end
  end
end
