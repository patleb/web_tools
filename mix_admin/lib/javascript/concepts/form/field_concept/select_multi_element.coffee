# TODO bug when open modal in nested form, events are gone in parent after closing modal
# when same attributes in modal (so do not allow nested of same model)

class RailsAdmin.Form.FieldConcept::SelectMultiElement extends RailsAdmin.Form.FieldConcept::SelectElement
  @include RailsAdmin.Form.FieldConcept::SelectMulti

  constructor: (@input) ->
    @initialize()
    super(@input)

  render: =>
    list = @render_list()
    @append_item(list, '', value: @BLANK, text: @include_blank) if @include_blank
    @remaining_options().each (option) =>
      @append_item(list, '', option)
    @show_field()
    @sm = new Js.StateMachine 'select_multi_keyup', {
      initialize: (sm) ->
        sm.initial = 'no_char'
        sm.keyups = ''
        sm.update_on_keyup_timeout = null
      triggers:
        keypress:
          '*': 'new_char'
          before: (sm, { new_char }) =>
            clearTimeout(sm.update_on_keyup_timeout)

            sm.keyups += new_char
            option = @remaining_options().find ({ text }) ->
              text.downcase().start_with(sm.keyups)
            if option && (item = @find_item(option)).length
              $(@SELECTED).removeClass('active')
              item.addClass('active')

            sm.update_on_keyup_timeout = setTimeout ->
              sm.trigger('timeout')
            , 1000
        timeout:
          '*': 'no_char'
          before: (sm) ->
            sm.keyups = ''
            sm.update_on_keyup_timeout = null
    }

  update_on_keyup: (event) =>
    if /[\w ]/.match(char = String.fromCharCode(event.which).downcase())
      @sm.trigger('keypress', new_char: char)

  update_on_keydown: (event) =>
    super(event)
    if event.which == $.ui.keyCode.SPACE
      event.preventDefault()

  #### PROTECTED ####

  show_field: =>
    # necessary for removing focus on the select empty list
    @keep_focus = true
    @placeholder.hide()
    setTimeout =>
      @placeholder.show().focus()
      @keep_focus = false

  set_control: =>
    @control = @placeholder

  #### PRIVATE ####

  find_item: ({ value }) =>
    $(@LIST).find_by('data-value': value)
