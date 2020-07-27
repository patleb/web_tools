class RailsAdmin.ExportConcept
  constants: ->
    SELECT_ALL: 'CLASS'
    CHECK_ALL: 'ID'
    FIELDS: '#js_export_fields label input'

  document_on: => [
    'click.continue', @SELECT_ALL, (event, target) ->
      target.closest(".control-group").find(".controls").find("input").each$ (input) ->
        input.prop(checked: !input.prop('checked'))

    'click.continue', @CHECK_ALL, (event, target) =>
      if target.is(':checked')
        $(@FIELDS).prop(checked: true)
      else
        $(@FIELDS).prop(checked: false)
  ]
