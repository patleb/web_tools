class RailsAdmin.PaginateConcept
  constants: ->
    BULK_FORM: RailsAdmin.BulkConcept
    LINK: 'CLASS'
    MAX: 'ID'
    SEPARATOR: ''

  document_on: => [
    'click', @LINK, (event, target) =>
      return if (link_wrapper = target).has_disable()

      $.ajax(
        url: link_wrapper.data('url')
        disable: "#{@LINK} a"
        fail: "#{@LINK} a"
        success: (data) =>
          @update_bulk_form(data)
          RailsAdmin.Table.CreateConcept.ready_again()
          RailsAdmin.TableConcept.ready_again()
          RailsAdmin.SortConcept.ready_again() if Main.sort_action
      )

    'change', @MAX, (event, target) ->
      Main.cookie_set('per', target.val().to_i())
      $.pjax.reload()
  ]

  #### PRIVATE ####

  update_bulk_form: (data) =>
    new_bulk_form = div$().html(data).find(@BULK_FORM)
    old_names = RailsAdmin.TableConcept.table_head_names()
    new_names = RailsAdmin.TableConcept.table_head_names(new_bulk_form.find('thead'))
    return $.pjax.reload() unless new_names.eql(old_names)

    old_table = RailsAdmin.TableConcept.table_body_rows().clone()
    old_table.last().addClass(@SEPARATOR)
    new_table = new_bulk_form.find('tbody')
    new_table.prepend(old_table)
    already_hidden = RailsAdmin.BulkConcept.hidden()
    $(@BULK_FORM).html(new_bulk_form.html())
    RailsAdmin.BulkConcept.show() unless already_hidden
