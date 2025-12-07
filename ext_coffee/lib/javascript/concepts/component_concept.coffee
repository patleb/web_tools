class Js.ComponentConcept
  alias: 'Js.Component'

  constants: ->
    ELEMENTS: '.js_component'
    INPUTS: -> "#{@ELEMENTS} [data-bind]"
    RENDER: 'js_component:render'

  events: -> [
    Js.Storage.CHANGE, Js.Storage.ROOT, @render_elements
    Js.Storage.CHANGE, Js.Storage.ROOT_PERMANENT, @render_elements

    'input', @INPUTS, ({ target }) ->
      element = @elements[target.closest(@ELEMENTS).getAttribute('data-uid')]
      name = target.getAttribute('data-bind')
      value = target.get_value()
      value_was = element.storage_value(name)
      if value_was is undefined or not eql value, value_was
        element.autofocus = name if document.activeElement is target
        element.storage_set("#{name}": value)
  ]

  ready: ->
    return unless (nodes = Rails.$(@ELEMENTS)).present()

    @elements = nodes.each_with_object [], (node, memo, index) =>
      element_type = node.getAttribute('data-element')
      element_class = "Js.Component.#{element_type.camelize('_')}Element".constantize()
      if node.find(@ELEMENTS) or node.find('[data-element]')
        throw "#{element_class} enclosing another Js.Component.Element type"
      uid = Math.uid()
      node.setAttribute('data-uid', uid)
      memo.push new element_class(node, uid, index)
    .sort_by((e) -> e.index)
    .map((e) -> [e.uid, e])
    .to_h()

    @elements.each (uid, element) ->
      element.ready_before?()
      element.ready()
      element.ready_after?()

  leave: ->
    @elements?.each (uid, element) ->
      element.leave?()
    @elements = null

  render_elements: ({ detail: { submitter, permanent, scope, changes } } = {}) ->
    elements = (@elements ? {}).select (uid, element) ->
      if not element.watch \
      or permanent isnt element.permanent \
      or scope is 'uid' and uid isnt element.uid \
      or not element.watch_scopes[scope]
        return false
      element_changes = if element.rendered and element.submitter is submitter
        element.update_self changes
      else
        element.render_self changes
      if not element_changes
        return false
      element_changes = element_changes.map (name, [change...]) ->
        [name, [change..., element["on_#{name}_change"]?(change...)]]
      element.on_storage_change?(element_changes.to_h())
      true
    elements.each (uid, element) -> Rails.refresh_csrf_tokens(element)
    Rails.fire(document, @RENDER, { elements }) unless elements.empty()

Js.Component = Js.ComponentConcept::
