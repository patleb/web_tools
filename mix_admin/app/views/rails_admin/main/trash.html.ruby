append :contextual_tabs, [
  @p.bulk.menu,
  @p.filter_box.menu
]

h_(
  @p.filter_box.render,
  form_tag(@p.bulk.form_path, method: :post, id: "js_bulk_form", remote: true, class: "form", novalidate: true) {[
    hidden_field_tag(:js_bulk_action),
    hidden_field_tag(:bulkable_type, 'bulkable_trash'),
    div_('.js_table_wrapper', [
      table_('.table.table-condensed.table-striped', @p.table.options, [
        thead_ do
          tr_('.js_table_row_head', [
            th_('.js_bulk_checkbox') do
              input_ '.js_bulk_toggle', type: "checkbox"
            end,
            @p.table.fields.map.with_index do |field, i|
              th_(@p.table.head_options(field, i)){ field.label.upcase_first }
            end,
          ])
        end,
        tbody_([
          @objects.map do |object|
            tr_(@p.table.row_options(object), [
              td_('.js_bulk_checkbox') do
                check_box_tag "bulk_ids[]", object.id, false
              end,
              @p.table.fields.map{ |field| field.bind(:object, object) }.map.with_index do |field, i|
                td_(@p.table.body_options(field, i)){ field.index_value_or_blank }
              end,
            ])
          end,
        ])
      ])
    ]),
    @p.paginate.render
  ]}
)
