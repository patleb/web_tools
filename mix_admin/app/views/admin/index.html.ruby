labels = {}
id, *fields = @section.fields
h_(
  div_('.model_info.dropdown', if: @section.description.present?) {[
    div_('.card.dropdown-content', tabindex: 0) do
      div_('.card-body', [
        p_{ @section.description },
      ])
    end,
    label_('.btn.btn-circle.btn-xs', icon('info-circle'), tabindex: 0, title: I18n.t('admin.misc.description')),
  ]},
  form_('.js_bulk_form.table_wrapper', method: :get) {[
    table_([
      thead_('.js_table_head') do
        tr_([
          th_(class: ('sticky' if @section.sticky?)) {[
            input_('.js_bulk_toggles.js_only.checkbox', type: 'checkbox', disabled: !@section.bulk_menu?),
            span_(labels[id.name] = id.label),
            id.sort_link,
          ]},
          fields.map do |field|
            th_([
              span_(labels[field.name] = field.label),
              field.sort_link,
            ])
          end
        ])
      end,
      tbody_('.js_table_body') {[
        @presenters.map do |presenter|
          id = id.with(presenter: presenter)
          tr_([
            th_(class: ('sticky' if @section.sticky?)) {[
              input_('.js_bulk_checkboxes.checkbox', type: 'checkbox', name: 'ids[]', value: id.value, disabled: !@section.bulk_menu?),
              span_('.field_value', class: id.css_class) {[
                @section.inline_menu(presenter),
                id.index_value,
              ]}
            ]},
            fields.map do |field|
              field = field.with(presenter: presenter)
              td_ '.tooltip', data: { tip: labels[field.name] } do
                span_('.field_value', field.index_value, class: field.css_class, tabindex: 0)
              end
            end
          ])
        end,
        tr_([
          th_(class: ('sticky' if @section.sticky?)) do
            @section.bulk_menu
          end,
          th_(colspan: fields.size),
        ]),
      ]},
    ]),
  ]},
  @section.pagination,
)
