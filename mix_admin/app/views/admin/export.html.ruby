# frozen_string_literal: true

count = @section.count
fields = @section.fields
root_fields = fields.reject{ |field| field.association? && !field.polymorphic? }
nested_fields = fields.select_map do |parent|
  next if !parent.association? || parent.polymorphic?
  model = parent.associated_model
  children = model.section(:export).fields.reject(&:association?)
  next if children.empty?
  [parent, children]
end
form_('.export_schema.card.indicator', action: @model.url_for(:export, **search_params)) {[
  span_('.indicator-item.indicator-center.badge', [count, t('admin.misc.records')], if: count),
  fieldset_('.card.collapse.collapse-arrow', unless: root_fields.empty?) {[
    input_(type: 'checkbox', checked: true),
    div_('.collapse-title', @model.label),
    div_('.card-body.collapse-content.grid', [
      @section.fields_toggle('.card-title.label', id: "model_#{@model.key}"),
      root_fields.map do |field|
        if_(field.association? && field.polymorphic?) {[
          @section.field_checkbox(field, "#{field.label} [id]"),
          @section.field_checkbox(field, "#{field.label} [type]", @model.columns.find{ |c| field.foreign_type == c.name }.name),
        ]} || (
          @section.field_checkbox(field)
        )
      end
    ])
  ]},
  nested_fields.map do |(parent, children)|
    fieldset_('.card.collapse.collapse-arrow') {[
      input_(type: 'checkbox', checked: true),
      div_('.collapse-title', parent.label),
      div_('.card-body.collapse-content.grid', [
        @section.fields_toggle('.card-title.label', id: "association_#{parent.name}"),
        children.map do |field|
          @section.field_checkbox(field, parent: parent)
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
