module Admin
  module Sections
    class Export < Index
      register_option :encoding, memoize: true do
        klass.encoding
      end

      def paginate
        false
      end

      def count
        return if countless?
        model.count(policy_scope(model.scope), self, **search_params)
      end

      def fields_toggle(label_class, id:)
        label_(label_class, class: 'js_only', for: id) {[
          span_('.label-text', t('admin.export.select_all_fields')),
          input_('.js_export_toggles.checkbox', type: 'checkbox', id: id),
        ]}
      end

      def field_checkbox(field, label = field.label, value = field.method_name, parent: nil)
        access = field.method? ? 'methods' : 'only'
        label_({ class: 'label', for: "schema_#{"include_#{parent.name}_" if parent}#{access}_#{value}"}, [
          span_('.label-text', label),
          input_('.js_export_checkboxes.checkbox', name: "schema#{"[include][#{parent.name}]" if parent}[#{access}][]",
            value: value, type: 'checkbox', checked: true, id: "schema_#{"include_#{parent.name}_" if parent}#{access}_#{value}"
          ),
        ])
      end
    end
  end
end
