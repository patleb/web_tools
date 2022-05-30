SUBMITABLE_BUTTON = 'button, input[type="button"], input[type="submit"], input[type="image"]'
event_submitter = null

do ->
  if 'submitter' of Event::
    return
  else if 'SubmitEvent' of window
    if /Apple Computer/.test(navigator.vendor)
      # See https://bugs.webkit.org/show_bug.cgi?id=229660
      prototype = window.SubmitEvent::
    else
      return
  prototype ?= window.Event::

  document.addEventListener 'click', (event) ->
    event_submitter = event.target.closest(SUBMITABLE_BUTTON)
  , true

  window.clear_event_submitter = ->
    event_submitter = null

  Object.defineProperty prototype, 'submitter',
    configurable: true,
    enumerable: true,
    get: ->
      return @_submitter if @_submitter
      candidates = [document.activeElement, event_submitter]
      event_submitter = null
      for candidate in candidates
        if candidate?.matches(SUBMITABLE_BUTTON) and @target is candidate.form
          return @_submitter = candidate
