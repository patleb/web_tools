class RailsAdmin.SortConcept
  constants: ->
    LIST: 'CLASS'
    ITEM: 'CLASS'
    HANDLE: 'CLASS'

  ready: =>
    $(@LIST).sortable(
      items: "> #{@ITEM}"
      axis: 'y'
      handle: @HANDLE
      cursor: 'grabbing'
      update: (event, ui) ->
        [prev, current, next] = [ui.item.prev(), ui.item, ui.item.next()]
        [prev_parent, current_parent, next_parent] = [prev.data('parent'), current.data('parent'), next.data('parent')]
        is_prev_item = current_parent == next_parent
        is_next_item = prev_parent == current_parent
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
