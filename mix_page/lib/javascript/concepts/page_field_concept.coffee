class Js.PageFieldConcept
  constants: ->
    LIST: 'CLASS'
    ITEM: 'CLASS'
    SORT: 'CLASS'

  document_on: => [
    'click', @SORT, (event, target) =>
      event.preventDefault()
  ]

  ready: =>
    $(@LIST).sortable(
      items: "> #{@ITEM}"
      axis: 'y'
      handle: @SORT
      cursor: 'grabbing'
      update: (event, ui) ->
        [previous, current, next] = [ui.item.prev(), ui.item, ui.item.next()]
        [previous_parent, current_parent, next_parent] = [previous.data('parent'), current.data('parent'), next.data('parent')]
        [current_level, next_level] = [current.data('level'), next.data('level')]
        is_previous_item = current_parent == next_parent
        is_next_item = previous.data('last') && previous_parent == current_parent
        is_last_item = !next_parent && current_level == 0
        is_last_item ||= (!next_parent || current_level > next_level) && previous_parent?.start_with(current_parent)
        unless current.data('last') && (is_previous_item || is_next_item || is_last_item)
          $(this).sortable('cancel')
          return
        id = current.data('id')
        list_previous_id = current.prevAll("[data-parent='#{current_parent}']:first").data('id')
        list_next_id = current.nextAll("[data-parent='#{current_parent}']:first").data('id')
        $.ajax(
          url: Routes.url_for('field_update', uuid: Page.uuid, id: id)
          method: 'PATCH'
          dataType: 'json'
          data: $.form_for(page_field: { list_previous_id, list_next_id })
          disable: this
          error: (xhr, status, error) =>
            message = if xhr.responseJSON? then xhr.responseJSON.flash.error else I18n.t('error')
            Flash.render('error', message)
            $(this).sortable('cancel')
        )
    )
