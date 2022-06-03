window.Turbolinks =
  supported: do ->
    window.history.pushState?

  enabled: ->
    Turbolinks.supported and Turbolinks.controller.enabled

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
