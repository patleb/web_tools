class Js.RescueConcept
  global: true

  ready_once: =>
    @rescues = []
    @skipped = []
    if process.env.NODE_ENV == 'production'
      window.addEventListener 'error', (event) =>
        if @skipped.find(string -> event.message?.includes(string))
          Logger.debug(event.message)
        else
          @on_error(
            message: event.message,
            backtrace: [event.slice(['filename', 'lineno', 'colno']).vals().join(':')],
          )
        event.preventDefault()
        false

  on_error: (rescue) =>
    rescue_string = JSON.stringify(rescue)
    if @rescues.excludes(rescue_string)
      @rescues.push(rescue_string)
      $.ajax(Routes.path_for('rescue'), { method: 'POST', data: { rescues_javascript: rescue }})
