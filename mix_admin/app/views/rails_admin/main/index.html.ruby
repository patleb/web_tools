# TODO turn member actions into a dropdown for mobile
# TODO specify which column is used as Id, make it clickable for show and frozen on x scroll
# TODO make title clickable for list view and home page
# TODO allow nestive helpers to take array as block outputted value
# TODO allow tag helpers to take array as block outputted value --> 'capture'... no, too low level, do it for each tag

append :contextual_tabs, [
  @p.bulk.menu,
  @p.filter_box.menu
]

h_(
  @p.filter_box.render,
  ul_('#scope_selector.nav.nav-tabs', unless: index_scopes.empty?) do
    index_scopes.map.with_index do |scope, i|
      scope = scope.to_s
      li_ class: ('active' if scope == index_scope || (index_scope.nil? && i == 0)) do
        a_ '.pjax', href: RailsAdmin.url_for(action: main_action, **@p.params.merge(scope: scope).with_keyword_access) do
          I18n.t("admin.scopes.#{@abstract_model.to_param}.#{scope}", default: I18n.t("admin.scopes.#{scope}", default: scope.titleize))
        end
      end
    end
  end,
  form_tag(@p.bulk.form_path, method: :post, id: "js_bulk_form", remote: true, class: "form", novalidate: true) do[
    hidden_field_tag(:js_bulk_action),
    p_(if: @p.table.description.present?){ strong_{ @p.table.description } },
    div_('.js_table_wrapper', [
      table_('.table.table-condensed.table-striped', @p.table.options, [
        thead_ do
          tr_('.js_table_row_head', [
            th_('.js_bulk_checkbox.hidden-xs') do
              input_ '.js_bulk_toggle', type: "checkbox"
            end,
            @p.table.fields.map.with_index do |field, i|
              th_(@p.table.head_options(field, i)){ field.label.upcase_first }
            end,
            th_
          ])
        end,
        tbody_([
          @p.table.inline_create,
          @objects.map do |object|
            tr_(@p.table.row_options(object), [
              td_('.js_bulk_checkbox.hidden-xs') do
                check_box_tag "bulk_ids[]", object.id, false
              end,
              @p.table.fields.map{ |field| field.bind(:object, object) }.map.with_index do |field, i|
                if field.inline_update?
                  @p.table.inline_update(object, field)
                else
                  td_(@p.table.body_options(field, i)){ field.index_value_or_blank }
                end
              end,
              td_('.table_row_actions') do
                ul_{ menu_for(@abstract_model, object, :member, true) }
              end
            ])
          end,
          tr_ do
            h_if @p.table.dynamic_columns? do[
              td_('.js_bulk_checkbox.hidden-xs'),
              @p.table.fields.map.with_index do |field, i|
                td_(@p.table.body_options(field, i)) do
                  div_('.js_table_remove_column.fa.fa-remove') if i != 0 && field.dynamic_column?
                end
              end,
              td_ do
                div_ '.js_table_restore_columns.fa.fa-undo'
              end
            ]end
          end
        ])
      ])
    ]),
    @p.paginate.render
  ]end
)
