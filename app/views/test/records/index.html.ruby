table_('.table_wrapper', [
  thead_(
    tr_ do
      @template.columns.map.with_index do |column, i|
        th_ class: { sticky: i == 0 } do
          span_ column
        end
      end
    end
  ),
  tbody_(
    @presenters.map do |presenter|
      tr_ do
        @template.columns.map.with_index do |column, i|
          td_ class: { sticky: i == 0 }, data: { tip: column } do
            span_ '.field_value', presenter[column], tabindex: 0
          end
        end
      end
    end,
  ),
])
