module Admin
  module Fields
    class HasMany < Association
      register_option :truncated? do
        true
      end

      register_option :eager_load do
        !count? && __super__(:eager_load)
      end

      register_option :count? do
        false
      end

      register_option :array_separator do
        '<br>'.html_safe
      end

      register_option :array_bullet do
        '- '.html_safe
      end

      def array?
        true
      end

      def format_array(value)
        if count?
          return unless value && value > 0
          return value unless (model = property_model).allowed?
          return value unless (field = self.model.associated_field(model))
          url = model.url_for(:index, q: { field.query_name => presenter[field.column_name] })
          a_('.link.link-primary', value, href: url)
        else
          super{ |v, i| block_given? ? yield(v, i) : format_value(v, property_fields[i]) }
        end
      end

      def format_array_index(value)
        if !count? && truncated
          return if value.empty?
          has_many = property_field.format_value(value.first)
          has_many = array_bullet + has_many if array_bullet && has_many.present?
          if (url = presenter.viewable_url(anchor: "#{name}_field"))
            has_many << ascii(:space)
            has_many << a_('.link.link-primary', ascii(:ellipsis), href: url)
          end
          has_many
        else
          format_array(value)
        end
      end

      def format_array_export(value, *)
        value = property_fields.map.with_index{ |field, i| field.format_export(value[i]) } unless count?
        super
      end

      def value
        return property_count if count?
        property_fields.map(&:value)
      end

      def method_name
        "#{through.to_s.singularize}_ids".to_sym
      end

      def property_field
        property_fields.first
      end

      def property_fields
        memoize(self, __method__, bindings) do
          presenter[through].order(column_name).select_map do |record|
            field_for record
          end
        end
      end

      def property_count
        memoize(self, __method__, bindings) do
          next unless (model = property_model).allowed?
          presenter.associated_count(through, model)
        end
      end
    end
  end
end
