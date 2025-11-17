class Js.ComponentConcept
  alias: 'Js.Component'

  constants: ->
    ELEMENTS: '.js_component'
    INPUTS: -> "#{@ELEMENTS} [data-bind]"
    CHANGE: 'js_component:change'

  events: -> [
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
    return unless (nodes = Rails.$(@ELEMENTS)).present()

    @elements = nodes.each_with_object {}, (node, memo) =>
      element_type = node.getAttribute('data-element') ? ''
      element_class = "Js.Component.#{element_type.camelize('_')}Element".constantize()
      if node.find(@ELEMENTS) or node.find('[data-element]')
        throw "#{element_class} enclosing another Js.Component.Element type"
      uid = Math.uid()
      node.setAttribute('data-uid', uid)
      memo[uid] = new element_class(node)
      memo[uid].uid = uid

    @elements.each_with_object [], (uid, element, memo) ->
      proto = Object.getPrototypeOf(element)
      unless memo.include(proto)
        memo.push(proto)
        element.ready_one?()
      element.ready_before?()
      element.ready()
      element.ready_after?()

  leave: ->
    @elements?.each (uid, element) ->
      element.leave?()
    @elements = null

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

Js.Component = Js.ComponentConcept::
