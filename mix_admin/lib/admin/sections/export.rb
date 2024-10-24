# frozen_string_literal: true

module Admin
  module Sections
    class Export < Index
      register_option :encoding do
        klass.encoding
      end

      def render
        count, fields = self.count, self.fields
        root_fields = fields.reject{ |field| field.association? && !field.polymorphic? }
        nested_fields = fields.select_map do |parent|
          next if !parent.association? || parent.polymorphic?
          model = parent.property_model
          children = model.export.fields.reject(&:association?)
          next if children.empty?
          [parent, children]
        end
        form_('.export_schema.card.indicator', action: model.url_for(:export, **search_params)) {[
          span_('.indicator-item.indicator-center.badge', [count, t('admin.misc.records')], if: count),
          fieldset_('.card.collapse.collapse-arrow', unless: root_fields.empty?) {[
            input_(type: 'checkbox', checked: true),
            div_('.collapse-title', model.label),
            div_('.card-body.collapse-content.grid', [
              fields_toggle('.card-title.label', id: "model_#{model.key}"),
              root_fields.map do |field|
                if_(field.association? && field.polymorphic?) {[
                  field_checkbox(field, "#{field.label} [id]"),
                  field_checkbox(field, "#{field.label} [type]", model.columns.find{ |c| field.foreign_type == c.name }.name),
                ]} || (
                  field_checkbox(field)
                )
              end
            ])
          ]},
          nested_fields.map do |(parent, children)|
            fieldset_('.card.collapse.collapse-arrow') {[
              input_(type: 'checkbox', checked: true),
              div_('.collapse-title', parent.label),
              div_('.card-body.collapse-content.grid', [
                fields_toggle('.card-title.label', id: "association_#{parent.name}"),
                children.map do |field|
                  field_checkbox(field, parent: parent)
                end
              ])
            ]}
          end,
          fieldset_('.card') {[
            div_('.card-body.grid', [
              div_('.flex.justify-between', [
                label_([
                  t('admin.export.csv.skip_header'),
                  icon('info-circle.tooltip', data: { tip: t('admin.export.csv.skip_header_help') }),
                ]),
                input_('.checkbox', name: 'csv_options[skip_header]', value: 'true', type: 'checkbox'),
              ]),
              label_({ class: 'label', for: 'csv_options[generator][col_sep]' }, [
                span_('.label-text', [
                  t('admin.export.csv.col_sep'),
                ]),
                select_('.select', ['todo'], name: 'csv_options[generator][col_sep]', required: true)
              ])
            ]),
          ]}
        ]}
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
