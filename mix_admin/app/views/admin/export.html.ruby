# create file in job
# use light_record gem (would be useful for charts as well) with find_each or in batches (uncached queries)
#   or #in_batches{ |relation| relation.pluck(...).each ... }
# write each line to tmp file to keep RAM low
# keep the file through active_storage
# serve file with nginx
#   or webrick in dev/test
#   https://stackoverflow.com/questions/765442/streaming-html-from-webrick
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
  span_('.indicator-item.indicator-center.badge', [count, I18n.t('admin.misc.records')], if: count),
  fieldset_('.card.collapse.collapse-arrow', unless: root_fields.empty?) {[
    input_(type: 'checkbox', checked: true),
    div_('.collapse-title', @model.label),
    div_('.card-body.collapse-content.grid', [
      @section.fields_toggle('.card-title.label', id: "model_#{@model.key}"),
      root_fields.map do |field|
        h_if(field.association? && field.polymorphic?) {[
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
