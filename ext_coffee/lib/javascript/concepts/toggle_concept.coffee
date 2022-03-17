class Js.ToggleConcept
  constants: ->
    SECTIONS: 'CLASS'
    CHECKBOXES: 'CLASS'

  constructor: ->
    @throttled_click = _.throttle(@on_click_section_target, 800)

  document_on: => [
    'click.continue', @SECTIONS, @throttled_click

    'click.continue', @CHECKBOXES, (event, target) =>
      checkboxes = target.data('targets')
      switch target[0].type
        when 'checkbox'
          if target.is(':checked')
            $(checkboxes).prop(checked: true)
          else
            $(checkboxes).prop(checked: false)
        else
          $(checkboxes).each$ (input) ->
            input.prop(checked: !input.prop('checked'))
  ]

  on_click_section_target: (event, target) ->
    icon = $(target.data('icon'))
    sections = $(target.data('targets'))
    { opened, closed } = icon.data()
    if icon.hasClass(opened)
      icon.toggleClass([opened, closed])
      sections.hide('slow')
    else if icon.hasClass(closed)
      icon.toggleClass([opened, closed])
      sections.show('slow')
    else
      throw 'invalid target'
