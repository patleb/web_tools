class RailsAdmin.Form.FieldConcept::SelectMultiRemoteElement extends RailsAdmin.Form.FieldConcept::SelectRemoteElement
  @include RailsAdmin.Form.FieldConcept::SelectMulti

  constructor: (@input) ->
    @initialize()
    super(@input)

  render: =>
    @render_list()
    @update_list(@control.val())
    @show_field()

  close: =>
    @placeholder.removeClass(@HIDE_CLASS)
    super()

  #### PRIVATE ####

  show_field: =>
    @control.addClass(@SHOW_CLASS)
    @input.addClass(@HIDE_CLASS)
    @keep_focus = true
    @control.click().focus().cursor_end(true)
    @placeholder.addClass(@HIDE_CLASS).hide()
    setTimeout =>
      @placeholder.show()
      @keep_focus = false
