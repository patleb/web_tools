class Js.ComponentConcept
  alias: 'Js.Component'

  constants: ->
    ELEMENTS: '.js_component'
    INPUTS: -> "#{@ELEMENTS} [data-bind]"
    CHANGE: 'js_component:change'

  document_on: -> [
    Js.Storage.CHANGE, Js.Storage.ROOT, @render_elements
    Js.Storage.CHANGE, Js.Storage.ROOT_PERMANENT, @render_elements

    'input', @INPUTS, ({ target }) ->
      element = @elements[target.closest(@ELEMENTS).getAttribute('data-uid')]
      name = target.getAttribute('data-bind')
      value = target.get_value()
      value_was = element.storage_value(name)
      if value_was is undefined or value isnt value_was
        element.storage_set("#{name}": value)
  ]

  ready: ->
    @ready_elements @ELEMENTS

  leave: ->
    @leave_elements()

  render_elements: ({ detail: { permanent, scope, changes } } = {}) ->
    elements = (@elements ? {}).select (uid, element) ->
      return if element.static
      return if permanent isnt element.permanent
      return if scope and scope isnt uid or not scope and element.scoped
      element.render_element(changes); true
    elements.each (uid, element) -> Rails.refresh_csrf_tokens(element)
    Rails.fire(document, @CHANGE, { elements }) unless elements.empty()

Js.Component = Js.ComponentConcept
