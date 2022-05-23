# Polyfill for CustomEvent in IE9+
# https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent#Polyfill
CustomEvent = window.CustomEvent

if typeof CustomEvent isnt 'function'
  CustomEvent = (event, params) ->
    evt = document.createEvent('CustomEvent')
    evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail)
    evt

  CustomEvent.prototype = window.Event.prototype

  # Fix setting `defaultPrevented` when `preventDefault()` is called
  # http://stackoverflow.com/questions/23349191/event-preventdefault-is-not-working-in-ie-11-for-custom-events
  { preventDefault } = CustomEvent.prototype
  CustomEvent.prototype.preventDefault = ->
    result = preventDefault.call(this)
    if @cancelable and not @defaultPrevented
      Object.defineProperty(this, 'defaultPrevented', get: -> true)
    result
