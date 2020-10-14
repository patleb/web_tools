append :contextual_tabs, [
  @p.filter_box.menu
]

h_(
  @p.filter_box.render,
  div_('#js_bulk_form') {[
    p_(if: @p.table.description.present?){ strong_{ @p.table.description } },
    div_('.js_table_wrapper', [
      table_('.table.table-condensed.table-striped', @p.table.options, [
        thead_ do
          tr_('.js_table_row_head', [
            th_ do
              input_ type: "checkbox", disabled: true
            end,
            @p.table.fields.map.with_index do |field, i|
              th_(@p.table.head_options(field, i)){ field.label.upcase_first }
            end,
            th_,
          ])
        end,
        tbody_('.js_sort_list', [
          div_('#js_sort_columns', data: { columns: @p.table.sort_action_columns }),
          @objects.map do |object|
            tr_('.js_sort_item', @p.table.row_sort_options(object), [
              td_('.js_sort_handle') do
                i_(class: 'fa fa-arrows-v')
              end,
              @p.table.fields.map{ |field| field.bind(:object, object) }.map.with_index do |field, i|
                td_(@p.table.body_options(field, i)){ field.index_value_or_blank }
              end,
              td_('.table_row_actions') do
                ul_{ menu_for(@abstract_model, object, :member, true) }
              end
            ])
          end,
        ])
      ])
    ]),
    @p.paginate.render
  ]}
)
