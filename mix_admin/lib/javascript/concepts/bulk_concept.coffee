class RailsAdmin.BulkConcept
  constants: =>
    MENU: 'ID'
    CHECKBOX: 'CLASS'
    HIDDEN_CHECKBOXES: => "#{@CHECKBOX} > input:hidden"
    LINK: 'CLASS'
    ACTION: 'ID'
    FORM: 'ID'
    TOGGLE: 'CLASS'

  document_on: => [
    'click', @MENU, (event, target) =>
      if @hidden()
        @show()
        RailsAdmin.TableConcept.refresh()
        target.dropdown('toggle')

    'click', @LINK, (event, target) =>
      $(@ACTION).val(target.data('action'))
      $(@FORM).submit()

    'click.continue', @TOGGLE, (event, target) ->
      $("[name='bulk_ids[]']").prop "checked", target.is(":checked")

    'keydown', @FORM, (event) ->
      event.preventDefault() if $.is_submit_key(event)
  ]

  hidden: =>
    $(@HIDDEN_CHECKBOXES).length - RailsAdmin.TableConcept.sticky_head().hidden()

  show: =>
    $(@HIDDEN_CHECKBOXES).parent().removeClass('hidden-xs')
