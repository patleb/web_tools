class Js.PageConcept
  global: true

  constants: ->
    TITLE: 'ID'
    WINDOW: 'ID'

  on: (events, handler) =>
    [@WINDOW, window].each (window_type) ->
      $(window_type).on(events, handler)

  off: (events) =>
    [@WINDOW, window].each (window_type) ->
      $(window_type).off(events)

  animate: (options) =>
    $("html, body, #{@WINDOW}").animate(options)
