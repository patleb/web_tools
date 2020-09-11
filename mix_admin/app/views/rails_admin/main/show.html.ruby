# TODO https://github.com/renderedtext/render_async
# TODO add fixed select to navigate through a long list of attributes

h_(
  if @model.report.available?
    report_action = RailsAdmin.action(:report, @abstract_model, @object)
    dl_ do
      a_('.btn.btn-primary', { href: report_path(model_name: @abstract_model.to_param), target: '_blank' }, [
        i_('.icon-white', class: report_action.link_icon),
        t("admin.export.confirmation", name: 'pdf')
      ])
    end
  end,
  main_section.visible_groups.map do |group|
    next if (fields = group.visible_fields).empty?
    next if (values = fields.map(&:formatted_value)).none?(&:present?) && RailsAdmin.config.compact_show_view
    div_('.fieldset', [
      h4_{ group.label },
      (p_{ group.help } if group.help),
      dl_ do
        fields.map.with_index do |field, index|
          h_unless(values[index].blank? && RailsAdmin.config.compact_show_view) {[
            dt_(class: field.css_classes(:term)) do
              span_{ field.label }
            end,
            dd_(class: field.css_classes(:definition)){ field.pretty_value_or_blank }
          ]}
        end
      end
    ])
  end
)
