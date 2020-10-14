class RailsAdmin.SortConcept
  constants: ->
    LIST: 'CLASS'
    ITEM: 'CLASS'
    HANDLE: 'CLASS'
    COLUMNS: 'ID'

  ready: =>
    columns = $(@COLUMNS).data('columns')
    $(@LIST).sortable(
      items: "> #{@ITEM}"
      axis: 'y'
      handle: @HANDLE
      cursor: 'grabbing'
      update: (event, ui) ->
        [prev, current, next] = [ui.item.prev(), ui.item, ui.item.next()]
        prev_columns = columns.map (column) -> prev.data('columns')[column]
        current_columns = columns.map (column) -> current.data('columns')[column]
        next_columns = columns.map (column) -> next.data('columns')[column]
        is_prev_item = current_columns.eql(next_columns)
        is_next_item = prev_columns.eql(current_columns)
        unless is_prev_item || is_next_item
          $(this).sortable('cancel')
          return
        id = current.data('id')
        list_prev_id = prev.data('id')
        list_next_id = next.data('id')
        $.ajax(
          url: Routes.url_for('sort', model_name: Main.model_name, inline: true)
          method: 'PUT'
          dataType: 'json'
          data: $.form_for("#{Main.model_name.underscore()}": { id, list_prev_id, list_next_id })
          disable: this
          done: current
          fail: current
          error: (xhr, status, error) =>
            Flash.error(xhr.responseJSON.flash.error)
            $(this).sortable('cancel')
        )
    )
