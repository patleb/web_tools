module Admin
  module Fields
    class HasOne < Association
      def editable?
        (nested? || klass.method_defined?("#{through}_id=")) && super
      end

      def method_name
        nested? ? "#{through}_attributes".to_sym : through
      end
    end
  end
end
