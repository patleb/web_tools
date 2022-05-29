SUBMITABLE_BUTTON = 'button, input[type="button"], input[type="submit"], input[type="image"]'
last_button = null

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
    last_button = event.target.closest(SUBMITABLE_BUTTON)
  , true

  window.clear_event_submitter = ->
    last_button = null

  Object.defineProperty prototype, 'submitter',
    configurable: true,
    enumerable: true,
    get: ->
      return @_submitter if @_submitter
      candidates = [document.activeElement, last_button]
      last_button = null
      for candidate in candidates
        if candidate?.matches(SUBMITABLE_BUTTON) and @target is candidate.form
          return @_submitter = candidate
