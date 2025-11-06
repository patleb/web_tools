class Js.PageConcept
  constants: ->
    UUID: '.js_page_uuid'
    LIST: '.js_page_field_list'
    ITEM: '.js_page_field'
    SORT: '.js_page_field_sort'

  ready: ->
    @uuid = Rails.find(@UUID)?.data('value')
    lists = sortable @LIST,
      items: @ITEM
      handle: @SORT
      forcePlaceholderSize: true
    lists.each (list) =>
      list.addEventListener 'sortupdate', (event) =>
        item = event.detail.item
        current_id = item.data('id')
        unless (sibling = item.next()) and (list_next_id = sibling.data('id'))
          unless (sibling = item.prev()) and (list_prev_id = sibling.data('id'))
            return
        Rails.ajax({
          type: 'POST'
          url: Routes.path_for('edit_page_field', uuid: @uuid, id: current_id)
          data: { page: { field: { list_prev_id, list_next_id } } }
          data_type: 'json'
          error: (response, status, xhr) ->
            Flash.alert(response.flash.alert)
        })

  leave: ->
    sortable(@LIST, 'destroy')
