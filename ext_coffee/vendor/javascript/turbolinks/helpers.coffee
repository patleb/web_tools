Turbolinks.dispatch = (name, { target, cancelable, data } = {}) ->
  event = document.createEvent('Events')
  event.initEvent(name, true, cancelable is true)
  event.data = data ? {}
  # Fix setting `defaultPrevented` when `preventDefault()` is called
  # http://stackoverflow.com/questions/23349191/event-preventdefault-is-not-working-in-ie-11-for-custom-events
  if event.cancelable and not preventDefaultSupported
    { preventDefault } = event
    event.preventDefault = ->
      unless this.defaultPrevented
        Object.defineProperty(this, 'defaultPrevented', get: -> true)
      preventDefault.call(this)
  (target ? document).dispatchEvent(event)
  event

preventDefaultSupported = do ->
  event = document.createEvent('Events')
  event.initEvent('test', true, true)
  event.preventDefault()
  event.defaultPrevented
