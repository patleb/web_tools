class Js.ComponentConcept
  alias: 'Js.Component'

  constants: ->
    ELEMENTS: '.js_component'
    INPUTS: => "#{@ELEMENTS} [data-watch]"

  document_on: -> [
    Js.Storage.CHANGE, Js.Storage.ROOT, ({ detail: { scope, changes } } = {}) =>
      @render_elements(scope, changes)

    'change', @INPUTS, (event, target) =>
      element = @elements[target.closest(@ELEMENTS).getAttribute('data-uid')]
      name = target.getAttribute('data-watch')
      value = target.get_value()
      value_was = element.get_value(name)
      if value_was is undefined or value isnt value_was
        element.set_data("#{name}": value)
  ]

  ready: ->
    @ready_elements @ELEMENTS

  leave: ->
    @leave_elements()

  render_elements: (scope, changes) ->
    @elements?.each (uid, element) ->
      return if scope and scope isnt uid or not scope and element.data_scoped()
      element.render_element(changes)
