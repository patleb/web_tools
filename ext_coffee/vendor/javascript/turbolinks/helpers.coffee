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

Turbolinks.uuid = ->
  result = ''
  for i in [1..36]
    if i in [9, 14, 19, 24]
      result += '-'
    else if i is 15
      result += '4'
    else if i is 20
      result += (Math.floor(Math.random() * 4) + 8).toString(16)
    else
      result += Math.floor(Math.random() * 15).toString(16)
  result
