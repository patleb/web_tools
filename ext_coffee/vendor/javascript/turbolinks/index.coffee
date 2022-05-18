window.Turbolinks =
  supported: do ->
    window.history.pushState?

  visit: (location, options) ->
    Turbolinks.controller.visit(location, options)

  update: (location) ->
    Turbolinks.controller.on_history_popped(location, Turbolinks.uid())

  clearCache: ->
    Turbolinks.controller.clear_cache()

  setProgressBarDelay: (delay) ->
    Turbolinks.controller.set_progress_bar_delay(delay)
