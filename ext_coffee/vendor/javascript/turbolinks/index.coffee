window.Turbolinks =
  supported: do ->
    window.history.pushState?

  visit: (location, options) ->
    Turbolinks.controller.visit(location, options)

  clearCache: ->
    Turbolinks.clear_cache()

  clear_cache: ->
    Turbolinks.controller.clear_cache()

  set_cache_size: (size) ->
    Turbolinks.Controller.cache_size = size # 0 to disable

  set_progress_bar_delay: (delay) ->
    Turbolinks.Controller.progress_bar_delay = delay

  set_http_request_timeout: (timeout) ->
    Turbolinks.HttpRequest.timeout = timeout # 0 to disable
