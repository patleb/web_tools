module Admin
  module Fields
    class HasMany < Admin::Field
      prepend Field::AsAssociation

      register_option :scope do
        nil
      end

      def multiple?
        true
      end

      def method_name
        "#{name.to_s.singularize}_ids".to_sym
      end

      def errors
        presenter[:errors][name]
      end

      private

      def records
        records = policy_scope(presenter[property.name])
        records = records.public_send(scope) if scope
        records
      end
    end
  end
end
