module Admin
  module Fields
    class HasOne < Association
      def editable?
        (nested? || klass.method_defined?("#{through}_id=")) && super
      end

      def method_name
        nested? ? "#{through}_attributes".to_sym : through
      end

      def property_id
        value.try(property.primary_key)
      end
    end
  end
end
