window.Rails = Rails.merge
  # Triggers a custom event on an element and returns false if the event result is false
  # obj::
  #   a native DOM element
  # name::
  #   string that corresponds to the event you want to trigger
  #   e.g. 'click', 'submit'
  # data::
  #   data you want to pass when you dispatch an event
  fire: (obj, name, data) ->
    event = new CustomEvent(name, bubbles: true, cancelable: true, detail: data)
    obj.dispatchEvent(event)
    not event.defaultPrevented

  # Helper function, needed to provide consistent behavior in IE
  stop_everything: (e) ->
    Rails.fire(e.target, 'ujs:everythingStopped')
    e.preventDefault()
    e.stopPropagation()
    e.stopImmediatePropagation()

  # Delegates events
  # to a specified parent `element`, which fires event `handler`
  # for the specified `selector` when an event of `event_type` is triggered
  # element::
  #   parent element that will listen for events e.g. document
  # selector::
  #   CSS selector; or an object that has `selector` and `exclude` properties (see: Rails.matches)
  # event_type::
  #   string representing the event e.g. 'submit', 'click'
  # handler::
  #   the event handler to be called
  delegate: (element, selector, event_type, handler) ->
    element.addEventListener event_type, (e) ->
      target = e.target
      target = target.parentNode until not (target instanceof Element) or target.matches(selector)
      if target instanceof Element and handler.call(target, e) is false
        e.preventDefault()
        e.stopPropagation()

  document_on: (event_type, selector, handler) ->
    Rails.delegate(document, selector, event_type, handler)

  is_meta_click: (event, method, data) ->
    (event.button? and event.button isnt 0) or (
      event.target?.isContentEditable or
        event.which > 1 or
        event.altKey or
        event.ctrlKey or
        event.metaKey or
        event.shiftKey
    ) and (method or 'GET').toUpperCase() is 'GET' and not data
