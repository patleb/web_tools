window.Turbolinks =
  supported: do ->
    window.history.pushState? and
      window.requestAnimationFrame? and
      window.addEventListener?

  visit: (location, options) ->
    Turbolinks.controller.visit(location, options)

  clearCache: ->
    Turbolinks.controller.clearCache()

  setProgressBarDelay: (delay) ->
    Turbolinks.controller.setProgressBarDelay(delay)
