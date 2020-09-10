class Js.PageFieldConcept
  constants: ->
    LIST: 'CLASS'
    ITEM: 'CLASS'

  ready: =>
    $(@LIST).sortable(
      items: "> #{@ITEM}"
      cursorAt: { top: 52 }
      axis: 'y'
      update: (event, ui) ->
        id = ui.item.data('id')
        list_previous_id = ui.item.prev().data('id')
        list_next_id = ui.item.next().data('id')
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
