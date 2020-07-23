class Js.MenuConcept
  constants: ->
    OVERLAY: 'CLASS'
    TOGGLE: 'CLASS'

  document_on: => [
    'click', @OVERLAY, (event) =>
      $(@TOGGLE).click()
      $(@OVERLAY).hide()

    'click', @TOGGLE, (event) =>
      if $(@TOGGLE).hasClass('collapsed')
        $(@OVERLAY).hide()
      else
        $(@OVERLAY).show()
  ]

  ready: =>
    unless $(@TOGGLE).hasClass('collapsed')
      $(@TOGGLE).click()
