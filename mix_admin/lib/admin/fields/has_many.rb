module Admin
  module Fields
    class HasMany < Association
      register_option :eager_load do
        !count? && __super__(:eager_load)
      end

      def array?
        true
      end

      def format_value(value, *)
        return super unless count?
        return unless value && value > 0
        return value unless (model = property_model).allowed?
        return value unless (field = self.model.associated_field(model))
        url = model.url_for(:index, q: { field.query_name => presenter[field.column_name] })
        a_('.link.link-primary', value, href: url)
      end

      def method_name
        "#{through.to_s.singularize}_ids".to_sym
      end
    end
  end
end
