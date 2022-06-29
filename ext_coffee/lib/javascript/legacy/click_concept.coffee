class Js.ClickConcept
  constants: ->
    SOURCE: 'CLASS'

  document_on: => [
    'click.continue', @SOURCE, (event, target) =>
      $(target.data('targets')).click()
  ]
