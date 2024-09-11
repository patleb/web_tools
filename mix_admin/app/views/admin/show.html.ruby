@section.groups.html_map do |group|
  next if (fields = group.fields).empty?
  div_('.group_fields', class: group.css_class) {[
    div_('.group', [
      h6_('.group_label', if: group.label) { group.label },
      p_('.group_help', if: group.help) { group.help },
    ]),
    dl_('.fields') do
      fields.map do |field|
        div_('.field', id: "#{field.name}_field") {[
          dt_('.field_label') do
            span_{ field.label }
          end,
          dd_('.field_value', class: field.css_class) do
            field.pretty_value
          end,
        ]}
      end
    end
  ]}
end
