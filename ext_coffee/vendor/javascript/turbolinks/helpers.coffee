window.Turbolinks = Turbolinks.merge
  enabled: ->
    Turbolinks.supported and Turbolinks.controller.enabled

  is_visitable: (element) ->
    Turbolinks.enabled() and Turbolinks.controller.is_visitable(element)

  visit: (location, options) ->
    Turbolinks.controller.visit(location, options)

  clear_cache: ->
    Turbolinks.controller.clear_cache()

  request_started: ->
    Turbolinks.controller.request_started()

  request_finished: ->
    Turbolinks.controller.request_finished()

  set_cache_size: (size) ->
    Turbolinks.Controller.cache_size = size # 0 to disable

  set_progress_bar_delay: (delay) ->
    Turbolinks.Controller.progress_bar_delay = delay

  set_http_request_timeout: (timeout) ->
    Turbolinks.HttpRequest.timeout = timeout # 0 to disable

  dispatch: (name, { target, cancelable, data } = {}) ->
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
