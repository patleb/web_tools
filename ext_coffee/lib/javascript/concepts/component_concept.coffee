class Js.ComponentConcept extends Js.Base
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

  render_elements: ({ detail: { submitter, permanent, scope, changes } } = {}) ->
    elements = (@elements ? {}).select (uid, element) ->
      if element.static or permanent isnt element.permanent or scope isnt element.scope
        false
      else if element.rendered and element is submitter
        element.refresh_storage()
        false
      else
        element.render_element(changes)
        true
    elements.each (uid, element) -> Rails.refresh_csrf_tokens(element)
    Rails.fire(document, @CHANGE, { elements }) unless elements.empty()

Js.Component = Js.ComponentConcept
