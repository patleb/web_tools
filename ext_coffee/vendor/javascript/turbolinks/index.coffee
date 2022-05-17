window.Turbolinks =
  supported: do ->
    window.history.pushState?

  visit: (location, options) ->
    Turbolinks.controller.visit(location, options)

  clearCache: ->
    Turbolinks.controller.clear_cache()

  setProgressBarDelay: (delay) ->
    Turbolinks.controller.set_progress_bar_delay(delay)
