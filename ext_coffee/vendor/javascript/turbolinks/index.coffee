window.Turbolinks =
  supported: do ->
    window.history.pushState?

  visit: (location, options) ->
    Turbolinks.controller.visit(location, options)

  clearCache: ->
    Turbolinks.controller.clear_cache()

  setCacheSize: (size) ->
    Turbolinks.Controller.cache_size = size # 0 to disable

  setProgressBarDelay: (delay) ->
    Turbolinks.Controller.progress_bar_delay = delay

  setHttpRequestTimeout: (timeout) ->
    Turbolinks.HttpRequest.timeout = timeout # 0 to disable
